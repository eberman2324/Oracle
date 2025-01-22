UPDATE s_security s
SET s.user_logon = user_logon || '_1' 
WHERE s.user_logon in ('Amanda','Charles','Christina','Dthomas','Ranger','Teresa','cdaniels','ggarcia','tmoore');
--9 rows

UPDATE s_security s
SET s.user_logon = user_logon || '_3' 
WHERE s.user_logon in ('william');
--1 row

UPDATE s_security s 
SET s.user_logon = user_logon || '_' 
WHERE s.user_logon in
('03springer','25252525','3589906','3600727','3605567','3605856','3606242','3607659','3613313','3613976','3615985','3618935','3620582','3626727','3772600','3922531','44844484','5147416','5151882','5154238','5157118','5158365','5159130','5180410','5181367','5182830','5184066','5511585','5633872','5915214','a229537','acctngirl','aclark','acolbert3','Agarcia','agarza','aharper','ahester','ahurley','Albert','Alexander','Alexandra','alfrog1964','alyssa1','Amanda','Amber123','amcbride','andrew86','anitastevensjay','ANTHONY','antwonydoss','anzeno','apeene','aphillips95','aportillo1','arangel','arrowhead','aseguin','Ashley89','astewart','atorres','atorres1','Baby2020','babygirl.kr2','baileya','banjoman','bbeltran1521','belliott','Benjamin','Beth1970','bjdavis56','blake123','Bluedog','bobbie','Bonnie','bowens','bowers12','bowser','Brenda','Brendan','breynolds','brucecole84','BUCHNERDAN','bullcv70','bwilson')
and user_logon not in ('Amanda','Charles','Christina','Dthomas','Ranger','Teresa','cdaniels','ggarcia','tmoore','william');
--84

UPDATE s_security s 
SET s.user_logon = user_logon || '_' 
WHERE s.user_logon in
('camacho','Camaro','carpio65','carrie','Catherine','cbowlby','cbroadus','ccoker143','cdaniels','cdeffibaugh','cehewitt','cgarner','challam1064','Chance','Charles','charles1982','Charlie01','ChrisD','christiekeck','Christina','christystinson765','chrisw','chuckharrington1969','CJohnson','clarkc','cmherrera','cmic1960','cmichael','coleman87','colyerdogoff','cometrider1','coreyd1011','Corinne','CPunsalang4411','craigsmith1962','croberts','crystalwilliams','cshelton','CThompson','cullen408','cutlerc','dallas','Dameihls','Danieljr','davesanders62','david01','DavidC','davisd3','dchaput','dcoates','DCosgrove','ddinisio','debmelton','debrumlen','dedwards1','deltadawn','Dennis','dennis01','derrellmacon','Dgallagher','dianamullenbach','dickson','dimples','DJACKSON1','djhartz63','dknlizsmoker','dmartinez','Dmitchell','dmorgan1','donaldc','donnajones','Douglas','drayttj','drogers1','dsmith','Dthomas','dvasquez','dwatkins','dweber','Dzamora')
and user_logon not in ('Amanda','Charles','Christina','Dthomas','Ranger','Teresa','cdaniels','ggarcia','tmoore','william');
--76

UPDATE s_security s 
SET s.user_logon = user_logon || '_' 
WHERE s.user_logon in
('ebea1202','eje959798','elittle','elmondy','emitchell','emontoya','erichardson','Eugene','eugenenorte','evella214','EWilson','fabtest','farronly','fld115','flemingp','flowers','Frances','francisco','franks','fredricksonn','gduthoy','genedavis','George','gerardogarcia','ggarcia','gmartinez','grandkids7','gregroth13','griffithj','grojas','Gsteve79','hinklej','hissonut1','hnewman','hrobertson','hutchew','jamesfleming','JamesM','Jamesr','janice','jasonharris','jasonmarcum','jbarajas','jburgess','jclauson','Jdavis','jdriscoll','Jeanette','jeburton','jengel','JenniferS','Jermaine','jerrysnyder1122','jessicah','jfischer','jgentry1','jheath','jheflin','JHenderson','jhester','jholman','jimmyd','jinez.inez','jkennedy','jlaw66','JMATTHEWS','Jmiranda','jncarter','johndeguzman57','johnnyhayes','jolson','Jones1980','jonesk','josem1400','Joseph','joyedst','Jperez','jperez','jrogers','jsbailey79','jscowden23','jserrano','Jthomas')
and user_logon not in ('Amanda','Charles','Christina','Dthomas','Ranger','Teresa','cdaniels','ggarcia','tmoore','william');
--82

UPDATE s_security s
SET s.user_logon = user_logon || '_' 
WHERE s.user_logon in
('jtmckinney','Jvaughn','jvining','jward76','jwarner','jyordy24','k.michellejames','kaboyd','Kaufmann1','kbanderson','kbidwell','kduncan','keithmkelley','keithwilliams','kejpe23','kelleynorman34','kemorris','khashizume','kilbyblack','kim1020','kkoosono','klackey28','krichards','kschmidt','ksteele','ktolbert','Kwoods','kylenelson','lacykey','landman','Larrym','lawsjl','Layaidaniel75','lbrown','lcastillo','lcooper','lcraig','ldavenport','Levonia1','lewist3','lgutierrez','lindaj','lmendoza','lmoore','lomack33','lpatrick','ltyson','Luanne','lucruz','Lunabug','MALBERT717','mariab','maribel','martinc','marz09016','mbarnard','mce0500046','megan1','Melissa','melvin','Mercado','metsfan5557','mfalcone','Mgreen','mgriffin','mharris1','michael1971','michael2020','Michelle','michellebobo70','mikeholden1986','mikelpz05','mikeobrien','missesc1','Mistic','Mitchell','mjohnston','mlarrick','mlewis','mmcdermott11','mmedlock')
and user_logon not in ('Amanda','Charles','Christina','Dthomas','Ranger','Teresa','cdaniels','ggarcia','tmoore','william');

--81

UPDATE s_security s
SET s.user_logon = user_logon || '_' 
WHERE s.user_logon in
('Mnichols','Moniquec','moorege','Morales','mpineda','mpowers','mrobinson','mstone','mudrl04','mullinl','Murphy','mvincent','Mwhite','mwillis','myboys050887','natasha1984','nathan','Newyork','nickeyturner07','ntanner2','Pamela','patrickdillon8605','pattymorga92','perry1','pgneubert','Pheim11','philip2020','phillip','plambert','pmurphy1','pyounts58','quickalisha','randerson','Ranger','rarnold','rcross','redsox','rharper','rholbrook','richard','robert','Robert1961','robingk','Rodriguez','rogelio','ronnieburns','rprice','rreyes','rstearns','russell0013','rvandermark','Rwilliams','rwilliams','sarahduncan','sbridges','schofielda','ScottB','scotthunt','scotts','scowden123','scraig3','seeforus7','sgilbert','shannon','shannon22','sharonb','shoulder','shudson','sickleave','skelton','skipmcgill','smartinez','smiller1','smoore','snowak','snowman','Stacey','stephaniemoreno','stephanieosborne','stevenryan','sthompson','sueann','SusanM')
and user_logon not in ('Amanda','Charles','Christina','Dthomas','Ranger','Teresa','cdaniels','ggarcia','tmoore','william');
--82

UPDATE s_security s
SET s.user_logon = user_logon || '_' 
WHERE s.user_logon in
('tammymorris25','tanderson','tarazelle','taylorc','taylorr','tbowman','tbulington','tcolbrese04','Teresa','teresamiller','thehenrys3','thoffman','thomase','tmoore','Tmoore','Tony63','TOsborn','traceychumley','tragesk','trisha21226','troypendleton87','troysmith','tshoaf78','twalker','vfarrow','vlindsey','walkerc','wiestk1','william','Williamj','wltitman','wpalmer','zfireman20','3624509','5182960','jvaladez','Ssanders')
and user_logon not in ('Amanda','Charles','Christina','Dthomas','Ranger','Teresa','cdaniels','ggarcia','tmoore','william');
--34