select count(*) from v$session where machine = 'ADD\MIDPWKABIS01'

select count(*) as Session_Count,machine,program from v$session where machine = 'ADD\MIDPWKABIS01' and
program = 'dllhost.exe'
GROUP BY machine,program