--[[
	シナリオ専用
	_SENDALL() で座標と変数を送信し合い、プレイヤーごとに管理する。99999.99m まで対応
--]]

--------------------[  Network  ]--------------------
rcs_NET = {
	ver = "1.01",	--ヴァージョン	意味あんのこれ

	sendframe =    5,	-- _SENDALL() を呼び出す頻度(f)
	waitframe = 30*2,	-- 一定フレーム取得できない場合、休止状態にする
	inseframe =   15,	-- 増殖バグを防止 (それでも変になったらＵを押してね！)

	count_pln   = 0,
	count_send  = 0,
	count_inse  = 0,

	ar_send = {0,0,0,0,},
	player_list = {},
}

function rcs_NET.Init()	--初期化
	count_pln = 0
	rcs_NET.count_send = 0
	rcs_NET.count_inse = 0

	ar_send = {0,0,0,0,}

	rcs_NET.clearList()
end

function rcs_NET.OnFrame()	--毎F実行
	if ( _PLAYERS() <= 0 and rcs_NET.count_pln <= 0 ) then	return	end

	----
	if (rcs_NET.count_inse > 0) then	rcs_NET.count_inse = rcs_NET.count_inse - 1	end

	if ( rcs_NET.count_pln ~= _PLAYERS() ) then
		rcs_NET.count_pln = _PLAYERS()
		rcs_NET.count_inse = rcs_NET.inseframe

		if (rcs_NET.count_pln <= 0) then
			rcs_NET.clearList()
			return
		end
	end

	----Send
	if (rcs_NET.count_send <= 0) then
		rcs_NET.count_send = rcs_NET.sendframe

		local arr
		arr = { _X(0)*100,_Y(0)*100,_Z(0)*100,
				rcs_NET.ar_send[1],rcs_NET.ar_send[2],rcs_NET.ar_send[3],rcs_NET.ar_send[4], }
		_SENDALL( Packet_encode( arr ) )

	else
		rcs_NET.count_send = rcs_NET.count_send - 1
	end

	----
	local i,j,e, str,pln,tan, fl
	pln = _PLAYERS() - 1
	tan = table.getn( rcs_NET.player_list )

	--out(0,"Network : "..pln)
	--out(2,"list : "..table.getn( rcs_NET.player_list ))

	if (rcs_NET.count_inse <= 0 and pln > tan ) then	--増援を確認する
		local list,ins = {},nil

		for i = 1,pln + 1 do	list[i] = false	end	--点呼用ﾘｽﾄ

		for i,e in next, rcs_NET.player_list do
			if ( e.num <= pln and not e.die ) then	list[ e.num+1 ] = true	end	--番号っ！
		end

		for i,e in next, list do		--で、空きを補充補充と
			if ( not e ) then
				j = i - 1	--PlayerNumber
				if ( _PLAYERID(j) ~= _PLAYERMYID() ) then
					ins = PlayerInfo.new()
					ins:init( _PLAYERNAME(j), _PLAYERID(j), j, 0,0,0 )

					table.insert( rcs_NET.player_list, ins )
				end
			end
		end
	end

	for i,e in next, rcs_NET.player_list do
		--out(i + 1, "how ary you? ",e.name)

		if ( e.die ) then	--お前はもう死んでいる
			table.remove( rcs_NET.player_list,i )
			--out(e.num+5,"good bye. ",e.name)

		elseif ( e.num > pln or e.id ~= _PLAYERID( e.num ) ) then	--番号とIDが合わない
			fl = false
			for j = 0,pln do
				if ( e.id == _PLAYERID( j ) ) then
					e.num = j
					e.name= _PLAYERNAME( j )
					fl = true
					break
				end
			end
			if ( not fl ) then	--ID一致しねぇよ！
				e:Die()
			end

		else
			if (e.sce) then	e.count_wait = e.count_wait + 1	end

			str = _RECEIVE( e.num )
			if ( str ~= "" ) then
				_RECEIVECLEAR( e.num )	--貴様は用済みだっ！
				if ( not e.sce ) then
					e:initinfo()
					e.sce = true
				end

				local arr = Packet_decode( str )
	
				e:update( e.count_wait, 
						{ arr[1]/100,arr[2]/100,arr[3]/100, },
						{ arr[4],arr[5],arr[6],arr[7] }
					)
			else
				if ( e.sce and e.count_wait > rcs_NET.waitframe ) then
					e:initinfo()
					e.sce = false
				end
			end
		end
		--drawTargetBox2( e:getPos() )
		--drawTargetBox2( e.newpos[1],e.newpos[2],e.newpos[3] )
	end	--for

end

function rcs_NET.setSendVal( va1,va2,va3,va4 )	--座標とともに送る変数を設定する(実数４つまで)
	local ar = rcs_NET.ar_send
	ar[1],ar[2],ar[3],ar[4] = va1,va2,va3,va4
end

function rcs_NET.clearList()
	local i,e
	for i,e in next, rcs_NET.player_list do
		e:Die()
	end

	while ( table.getn( rcs_NET.player_list ) > 0 ) do
		table.remove( rcs_NET.player_list, 1 )
	end
end

function rcs_NET.print( o )
	local i,e
	for i,e in next, rcs_NET.player_list do
		out( o + e.num, "Hello. "..e.name..". "..(e.sce and "TRUE" or "FALSE") )
	end
end

--------------------[  PlayerInfo  ]--------------------
PlayerInfo = {}
PlayerInfo_mt = { __index = PlayerInfo }

PlayerInfo.val_vec1  = 0.6	--予測用定数
PlayerInfo.val_vec2  = -1

function PlayerInfo.new()
	local temp = {
		name, id, num, sce,die, wait,count_wait,
		newpos, befpos, vec,val = {},{},{},{}
	}
	return setmetatable( temp, PlayerInfo_mt )
end
function PlayerInfo:init( name, id, num, xx,yy,zz )
	self.id   = id
	self.num  = num
	self.name = name

	self.die  = false	--リストから消去されたか
	self.sce  = false	--送受信が可能か
	self:initinfo()
end
function PlayerInfo:initinfo()
	self.newpos = { 0,-1000000,0 }
	self.befpos = {nil,nil,nil}
	self.vec    = {nil,nil,nil}
	self.val    = { 0,0,0,0, }

	self.wait   = 1		--送受信に掛かった時間(f)
	self.count_wait = 0		--待ってます…
end
function PlayerInfo:isUse()	return (self.sce and not self.die)	end	--座標とか取得できる状態か？ ガベージコレクトを信じましょう。
function PlayerInfo:Die()	self.die,self.sce = true,false	end	--何か消されちゃった

function PlayerInfo:getVal( n )
	return self.val[ n ]
end

function PlayerInfo:getPos()	----座標取得
	return self.newpos[1],self.newpos[2],self.newpos[3]
end
function PlayerInfo:getPos2()	----位置予測込みで取得する
	local pos,i = {},0
	pos = { 0,0,0, }
	if ( self.vec[1] ) then
		for i=1,3 do	pos[i] = self.newpos[i] + self.vec[i] * (self.count_wait + PlayerInfo.val_vec2) / self.wait * PlayerInfo.val_vec1 	end
	else
		for i=1,3 do	pos[i] = self.newpos[i]	end
	end

	return pos[1],pos[2],pos[3]
end
function PlayerInfo:update( ww, pos, val )
	local i = 0

	if ( self.befpos[1] ) then
		for i=1,3 do	self.vec[i] = pos[i] - self.befpos[i]	end
	else
		for i=1,3 do	self.vec[i] = 0	end
	end

	for i=1,3 do
		self.befpos[i] = self.newpos[i]
		self.newpos[i] = pos[i]
	end

	for i=1,4 do
		self.val[i] = val[i]
	end

	self.wait = ww
	self.count_wait = 0
end
--------------------[  Packet  ]--------------------
function Packet_encode( val )		-- +- 99999.99m まで対応
	return string.format( "%+08d%+08d%+08d%+08d%+08d%+08d%+08d",
		val[1],val[2],val[3], val[4],val[5],val[6],val[7] )
end

function Packet_decode( str )
	local val,len, sg,gu, w,j
	val = { 0,0,0, 0,0,0,0 }
	len = string.len( str )
	w = ""
	sg,gu,j = 0,0,0

	for i=1,len do
		w = string.sub(str,i,i)
		if (j > 7 or w == nil) then	break	end
		if	(w == "+") then
			j = j + 1	gu = 7-1	sg =  1
		elseif	(w == "-") then
			j = j + 1	gu = 7-1	sg = -1
		elseif ( j > 0 ) then
			val[j] = val[j] + (string.byte(w)-48) * 10^gu * sg
			gu = gu - 1
		end
	end

	return {	val[1],val[2],val[3],val[4],val[5],val[6],val[7],	}
end
