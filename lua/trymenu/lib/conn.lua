module("conn", package.seeall)

connTable = {
	host='192.168.28.27',
	port=3306,
	database='try_game4',
	user='root',
	password='123456',
}

connRedis = {
	host='192.168.20.62',
	port=6379,
	pool=30,
	max_idle_timeout=1000*10,
}