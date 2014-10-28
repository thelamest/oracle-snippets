/* from http://psoug.org/snippet/Display-locks-and-latches_525.htm */

SET pagesize 23
 
col sid format 999999
col serial# format 999999
col username format a12 TRUNC
col process format a8 TRUNC
col terminal format a12 TRUNC
col TYPE format a12 TRUNC
col lmode format a4 TRUNC
col lrequest format a4 TRUNC
col object format a73 TRUNC
 
SELECT s.sid, s.serial#,
       DECODE(s.process, NULL,
          DECODE(SUBSTR(p.username,1,1), '?',   UPPER(s.osuser), p.username),
          DECODE(       p.username, 'ORACUSR ', UPPER(s.osuser), s.process)
       ) process,
       NVL(s.username, 'SYS ('||substr(p.username,1,4)||')') username,
       DECODE(s.terminal, NULL, RTRIM(p.terminal, CHR(0)),
              UPPER(s.terminal)) terminal,
       DECODE(l.TYPE,
          -- Long locks
                      'TM', 'DML/DATA ENQ',   'TX', 'TRANSAC ENQ',
                      'UL', 'PLS USR LOCK',
          -- Short locks
                      'BL', 'BUF HASH TBL',  'CF', 'CONTROL FILE',
                      'CI', 'CROSS INST F',  'DF', 'DATA FILE   ',
                      'CU', 'CURSOR BIND ',
                      'DL', 'DIRECT LOAD ',  'DM', 'MOUNT/STRTUP',
                      'DR', 'RECO LOCK   ',  'DX', 'DISTRIB TRAN',
                      'FS', 'FILE SET    ',  'IN', 'INSTANCE NUM',
                      'FI', 'SGA OPN FILE',
                      'IR', 'INSTCE RECVR',  'IS', 'GET STATE   ',
                      'IV', 'LIBCACHE INV',  'KK', 'LOG SW KICK ',
                      'LS', 'LOG SWITCH  ',
                      'MM', 'MOUNT DEF   ',  'MR', 'MEDIA RECVRY',
                      'PF', 'PWFILE ENQ  ',  'PR', 'PROCESS STRT',
                      'RT', 'REDO THREAD ',  'SC', 'SCN ENQ     ',
                      'RW', 'ROW WAIT    ',
                      'SM', 'SMON LOCK   ',  'SN', 'SEQNO INSTCE',
                      'SQ', 'SEQNO ENQ   ',  'ST', 'SPACE TRANSC',
                      'SV', 'SEQNO VALUE ',  'TA', 'GENERIC ENQ ',
                      'TD', 'DLL ENQ     ',  'TE', 'EXTEND SEG  ',
                      'TS', 'TEMP SEGMENT',  'TT', 'TEMP TABLE  ',
                      'UN', 'USER NAME   ',  'WL', 'WRITE REDO  ',
                      'TYPE='||l.TYPE) TYPE,
       DECODE(l.lmode, 0, 'NONE', 1, 'NULL', 2, 'RS', 3, 'RX',
                       4, 'S',    5, 'RSX',  6, 'X',
                       TO_CHAR(l.lmode) ) lmode,
       DECODE(l.request, 0, 'NONE', 1, 'NULL', 2, 'RS', 3, 'RX',
                         4, 'S', 5, 'RSX', 6, 'X',
                         TO_CHAR(l.request) ) lrequest,
       DECODE(l.TYPE, 'MR', DECODE(u.name, NULL,
                            'DICTIONARY OBJECT', u.name||'.'||o.name),
                      'TD', u.name||'.'||o.name,
                      'TM', u.name||'.'||o.name,
                      'RW', 'FILE#='||substr(l.id1,1,3)||
                      ' BLOCK#='||substr(l.id1,4,5)||' ROW='||l.id2,
                      'TX', 'RS+SLOT#'||l.id1||' WRP#'||l.id2,
                      'WL', 'REDO LOG FILE#='||l.id1,
                      'RT', 'THREAD='||l.id1,
                      'TS', DECODE(l.id2, 0, 'ENQUEUE',
                                             'NEW BLOCK ALLOCATION'),
                      'ID1='||l.id1||' ID2='||l.id2) object
FROM   sys.v_$lock l, sys.v_$session s, sys.obj$ o, sys.USER$ u,
       sys.v_$process p
WHERE  s.paddr  = p.addr(+)
  AND  l.sid    = s.sid
  AND  l.id1    = o.obj#(+)
  AND  o.owner# = u.USER#(+)
  AND  l.TYPE   <> 'MR'
UNION ALL                          /*** LATCH HOLDERS ***/
SELECT s.sid, s.serial#, s.process, s.username, s.terminal,
       'LATCH', 'X', 'NONE', h.name||' ADDR='||rawtohex(laddr)
FROM   sys.v_$process p, sys.v_$session s, sys.v_$latchholder h
WHERE  h.pid  = p.pid
  AND  p.addr = s.paddr
UNION ALL                         /*** LATCH WAITERS ***/
SELECT s.sid, s.serial#, s.process, s.username, s.terminal,
       'LATCH', 'NONE', 'X', name||' LATCH='||p.latchwait
FROM   sys.v_$session s, sys.v_$process p, sys.v_$latch l
WHERE  latchwait IS NOT NULL
  AND  p.addr      = s.paddr
  AND  p.latchwait = l.addr
/
 
