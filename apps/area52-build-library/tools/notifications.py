"""Private publication status messages; no request-state changes or publication retries."""
import base64
import hashlib
import json
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape

MESSAGES={
 'catalog':'Publication paused: server catalog rules changed and the worker needs requalification. Your request is retained; do not publish another copy.',
 'unavailable':'Publication paused: the worker could not complete its checks or contact GitHub. Your request is retained; no duplicate is needed.',
 'uncertain':'GitHub publication readback is pending. The worker will check the existing commit; it will not repeat the write. Your request is retained.',
 'conflict':'Publication stopped: validation or repository content conflicts require operator review. Your saved build is preserved.',
 'failed':'Publication stopped: the saved build failed worker catalog/format validation. Your saved build is preserved; ask a GM to review this revision.',
 'published':'Build published to the public Area 52 Shared Library on GitHub. Publication and file readback confirmed.',
}

def send_private(name,message):
    if not re.fullmatch(r'[A-Za-z]{2,12}',name):raise ValueError('Unsupported recipient name')
    command='send message '+name+' "Area 52 Library: '+message+'"'
    credentials=json.loads(Path('/home/dml/games/ascension-freepick-test/private/remote-gm/credentials.json').read_text())
    body='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="urn:AC"><SOAP-ENV:Body><ns1:executeCommand><command>'+escape(command)+'</command></ns1:executeCommand></SOAP-ENV:Body></SOAP-ENV:Envelope>'
    authorization=base64.b64encode((credentials['username']+':'+credentials['password']).encode()).decode()
    pid=subprocess.check_output(['docker','inspect','ascension-freepick-worldserver','--format','{{.State.Pid}}'],text=True).strip()
    if not pid.isdecimal() or int(pid)<1:raise RuntimeError('Realm unavailable for status message')
    child='import json,sys,urllib.request\nr=json.load(sys.stdin)\nq=urllib.request.Request("http://127.0.0.1:7878/",data=r["body"].encode(),headers={"Content-Type":"text/xml; charset=utf-8","SOAPAction":"urn:AC#executeCommand","Authorization":"Basic "+r["authorization"]})\nwith urllib.request.urlopen(q,timeout=30) as s: print(s.read().decode())\n'
    result=subprocess.run(['nsenter','-t',pid,'-n','python3','-c',child],input=json.dumps({'body':body,'authorization':authorization}),capture_output=True,text=True,timeout=40)
    if result.returncode:raise RuntimeError('Private status delivery unavailable')
    response=ET.fromstring(result.stdout)
    if any(e.tag.endswith('Fault') for e in response.iter()):raise RuntimeError('Private status delivery rejected')

def notify(config,queue,database,blocked=None,sender=send_private):
    since=config.get('notification_since')
    if not since:return
    if not re.fullmatch(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}',since):raise ValueError('Invalid notification start')
    queue.connection.execute('CREATE TABLE IF NOT EXISTS notification_receipts (key TEXT PRIMARY KEY,state TEXT NOT NULL)')
    queue.connection.commit()
    rows=database("SELECT JSON_OBJECT('owner',p.owner_account,'token',p.request_token,'queue',p.queue_id,'state',p.state,'name',c.name) FROM area52_library_publication p JOIN characters c ON c.account=p.owner_account AND c.online=1 WHERE p.created_at >= '"+since+"' ORDER BY p.created_at DESC LIMIT 100;")
    for line in rows.splitlines():
        row=json.loads(line);state=row['state'];code=None
        if state in ('published','failed','conflict'):code=state
        elif state in ('queued','accepted'):
            code=blocked
            if row['queue']:
                request=queue.get(row['queue'])
                if request['state']=='uncertain':code='uncertain'
                elif request['state']=='conflict':code='conflict'
                elif request.get('error'):code=code or 'unavailable'
        if code not in MESSAGES:continue
        key=hashlib.sha256(json.dumps([row['owner'],row['token'],row['name'],code]).encode()).hexdigest()
        # Reserve before send: uncertain SOAP responses never cause automatic duplicate messages.
        inserted=queue.connection.execute('INSERT OR IGNORE INTO notification_receipts VALUES (?,?)',(key,'reserved')).rowcount
        queue.connection.commit()
        if not inserted:continue
        try:sender(row['name'],MESSAGES[code])
        except Exception:
            queue.connection.execute('UPDATE notification_receipts SET state=? WHERE key=?',('uncertain',key));queue.connection.commit();continue
        queue.connection.execute('UPDATE notification_receipts SET state=? WHERE key=?',('sent',key));queue.connection.commit()
