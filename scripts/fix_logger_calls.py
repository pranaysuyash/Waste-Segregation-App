import re
from pathlib import Path
root=Path('.')
pattern=re.compile(r"WasteAppLogger\.(debug|fine|info|warning|severe)\s*\((.*?)\);", re.S)
files=list(root.rglob('lib/**/*.dart'))
changed=0
for f in files:
    s=f.read_text()
    def repl(m):
        fn=m.group(1)
        args=m.group(2).strip()
        parts=[]
        cur=''
        depth=0
        for ch in args:
            if ch in '({[':
                depth+=1
            elif ch in ')}]':
                depth-=1
            if ch==',' and depth==0:
                parts.append(cur.strip())
                cur=''
            else:
                cur+=ch
        if cur.strip(): parts.append(cur.strip())
        if len(parts)==0:
            return m.group(0)
        msg=parts[0]
        named=[]
        if len(parts)>=2 and parts[1] and parts[1] != 'null':
            named.append('error: '+parts[1])
        if len(parts)>=3 and parts[2] and parts[2] != 'null':
            named.append('stackTrace: '+parts[2])
        if len(parts)>=4 and parts[3] and parts[3] != 'null':
            named.append('context: '+parts[3])
        if named:
            return f'WasteAppLogger.{fn}({msg}, '+', '.join(named)+');'
        else:
            return f'WasteAppLogger.{fn}({msg});'
    new=pattern.sub(repl, s)
    if new!=s:
        f.write_text(new)
        changed+=1
print('changed files',changed)
