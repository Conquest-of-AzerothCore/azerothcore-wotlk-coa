import base64
import json
from pathlib import Path
import secrets
import time
import urllib.error
import urllib.request
from xml.etree import ElementTree
from xml.sax.saxutils import escape

DESCRIPTOR_KEYS = ("instance", "slot", "soap_url", "soap_account", "soap_password_file", "account", "character",
                   "deployed_commit", "deployed_at", "preflight", "preflight_slot", "preflight_time")

ENVELOPE = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="urn:AC">'
    "<SOAP-ENV:Body><ns1:executeCommand><command>{command}</command></ns1:executeCommand></SOAP-ENV:Body>"
    "</SOAP-ENV:Envelope>"
)


class SoapFault(Exception):
    pass


def _find(root, name):
    return next((element for element in root.iter() if element.tag.rsplit("}", 1)[-1] == name), None)


def soap_execute(url, account, password, command, timeout=10.0):
    request = urllib.request.Request(url, data=ENVELOPE.format(command=escape(command)).encode("utf-8"),
                                     method="POST")
    request.add_header("Content-Type", "text/xml; charset=utf-8")
    token = base64.b64encode(f"{account}:{password}".encode()).decode()
    request.add_header("Authorization", f"Basic {token}")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = response.read()
    except urllib.error.HTTPError as error:
        payload = error.read()
        error.close()
        if not payload or error.code in (401, 403):
            raise SoapFault(f"HTTP {error.code} from {url}") from None
    try:
        root = ElementTree.fromstring(payload)
    except ElementTree.ParseError as error:
        raise SoapFault(f"unreadable SOAP reply: {error}: {payload[:200]!r}") from None
    fault = _find(root, "Fault")
    if fault is not None:
        text = _find(fault, "faultstring")
        raise SoapFault((text.text or "").strip() if text is not None else "SOAP fault")
    result = _find(root, "result")
    if result is None:
        raise SoapFault(f"no result element in SOAP reply: {payload[:200]!r}")
    return result.text or ""


def load_descriptor(path):
    descriptor = json.loads(Path(path).read_text(encoding="utf-8"))
    missing = [key for key in DESCRIPTOR_KEYS if key not in descriptor]
    if missing:
        raise ValueError(f"lab descriptor {path} lacks {', '.join(missing)}")
    return descriptor


def probe(descriptor, line, timeout=10.0, poll=0.2):
    password = Path(descriptor["soap_password_file"]).read_text(encoding="utf-8").strip()
    character = descriptor["character"]
    req = "r" + secrets.token_hex(6)

    def run(command):
        return soap_execute(descriptor["soap_url"], descriptor["soap_account"], password, command).strip()

    started = time.monotonic()
    run(f".labprobe send {character} {req} {line}")
    while True:
        status = run(f".labprobe result {character} {req}")
        if status.startswith("complete "):
            answer = json.loads(base64.b64decode(status.split(" ", 1)[1]).decode("utf-8"))
            answer["elapsed_ms"] = int((time.monotonic() - started) * 1000)
            return answer
        if time.monotonic() - started >= timeout:
            raise TimeoutError(f"no relay answer from {character} for {req} after {timeout:g}s "
                               f"(last status: {status})")
        time.sleep(poll)
