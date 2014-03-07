UPDATE GAME_LIST_ITEM SET ItemNewTip='' where ItemNewTip='NULL';
UPDATE GAME_LIST_ITEM SET ItemExtraTip='' where ItemExtraTip='NULL';
UPDATE GAME_LIST_ITEM SET ItemUrl='' where ItemUrl='NULL';
UPDATE GAME_LIST_ITEM SET BeginTime='2013-1-1 00:00:00' ;
UPDATE GAME_LIST_ITEM SET EndTime='2099-1-1 00:00:00' ;
UPDATE GAME_LIST_ITEM SET ItemParent='' where ItemParent='NULL';
UPDATE GAME_LIST_ITEM SET mycategorycode='' where mycategorycode='NULL';
UPDATE GAME_LIST_ITEM SET HelpURL='' where HelpURL='NULL';
UPDATE GAME_LIST_ITEM SET EName='' where EName='NULL';
UPDATE GAME_LIST_ITEM SET channelcode='' where channelcode='NULL';
UPDATE GAME_LIST_ITEM SET rootcode='' where rootcode='NULL';
UPDATE GAME_LIST_ITEM SET mygamecode='' where mygamecode='NULL';
-- 去除<font>之类的字符
UPDATE GAME_LIST_ITEM SET ItemName = MID(`ItemName`,1,LOCATE('<',ItemName)-1) WHERE LOCATE('<',ItemName) > 1;
-- 去除￥符号
UPDATE GAME_LIST_ITEM SET ItemName = REVERSE(MID(REVERSE(`ItemName`),1,LOCATE('￥',REVERSE(`ItemName`))-1)) WHERE LOCATE('￥',REVERSE(`ItemName`)) > 1;
-- 去除$符号
UPDATE GAME_LIST_ITEM SET ItemName = REVERSE(MID(REVERSE(`ItemName`),1,LOCATE('＄',REVERSE(`ItemName`))-1)) WHERE LOCATE('＄',REVERSE(`ItemName`)) > 1;
-- 将[]内容保存在`ItemExtraTip`中
UPDATE GAME_LIST_ITEM SET ItemExtraTip = REVERSE(MID(REVERSE(`ItemName`),1,LOCATE('[',REVERSE(`ItemName`)))) WHERE LOCATE('[',`ItemName`) > 1;
-- 去除[]内容
UPDATE GAME_LIST_ITEM SET ItemName = MID(`ItemName`,1,LOCATE('[',`ItemName`)-1) WHERE LOCATE('[',`ItemName`) > 1;
-- 去除<font>包括的字符
UPDATE GAME_LIST_ITEM SET ItemName = MID(`ItemName`,LOCATE('<b>',ItemName)+3) WHERE LOCATE('<',ItemName) = 1;
UPDATE GAME_LIST_ITEM SET ItemName = MID(`ItemName`,1,LOCATE('</b>',ItemName)-1) WHERE LOCATE('</b>',ItemName) > 1;

-- 去除site的字符
UPDATE GAME_SITE SET sitename = MID(`sitename`,1,LOCATE('site',sitename)-1) WHERE LOCATE('site',sitename) > 1;


