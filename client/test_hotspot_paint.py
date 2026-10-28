from pathlib import Path
import sys,json
T=Path(__file__).resolve().parent
from lupa.lua51 import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True);s=(T/'Interface/FrameXML/XPHotspots.lua').read_text(encoding='utf-8');assert lua.eval('function(s)return loadstring(s)~=nil end')(s)
start=s.index('local function LocalCount()');end=s.index('function H.UpdateDesignAccess()',start)
code=s[start:end]
lua.execute('''H={queue={},localStrokes={}};draft={map=1,zone=14,kind="polygon"};gm=true
function N(v)return tonumber(v) or 0 end
function View()return 1,14,0,6400,0,9600 end
function Overview()return false end
function GetTime()return 0 end
function IsControlKeyDown()return true end
function PaintPosition()return px,py end
function PaintCursor()end
function Notify(t)message=t end
sent={};function Send(t)table.insert(sent,t)end
WorldMapButton={};function WorldMapButton:GetWidth()return 960 end;function WorldMapButton:GetHeight()return 640 end
function WorldMapButton:CreateTexture()local t={};function t:SetTexture(r,g,b,a)self.red=r;self.green=g end;return setmetatable(t,{__index=function()return function()end end})end
function H.Highlight()end
'''+code)
lua.execute('''H.localBase={map=1,zone=14,id=1,revision=1};local st={mode="Brush",kind="round",radius=75,points={}};H.localStrokes={st};H.stroke=st
for i=1,192 do st.points[i]={x=100+i,y=100} end
px=1000;py=100;H.SamplePaint();assert(#st.points==192 and H.paintInvalid and not H.stroke);assert(H.paintFills[1].red==1 and H.paintFills[1].green==0.1)
H.SaveLocalPaint("150 3600 1 3600 1 1 0 test");assert(H.localSaving and #sent<=128 and #sent>2)
for _,v in ipairs(sent)do assert(#v<=240)end
H.localSaving=nil;H.UndoLocalPaint();assert(#H.localStrokes==0 and not H.paintInvalid)
st={mode="Brush",kind="round",radius=75,points={{x=100,y=100}}};H.localStrokes={st};H.stroke=st;px=19001;py=100;H.SamplePaint();assert(#st.points==1 and H.paintInvalid)
H.ClearLocalPaint();assert(not H.paintInvalid and #H.localStrokes==0)
''')
print('Lua painting limit/preview/upload regressions passed.')
