--[[
	モデル部分
--]]
------------------------[ Object ]---------------------------------
rcs_Model = {}
rcs_Model_mt = { __index=rcs_Model }

rcs_Model.name = "Plane_M"

--------------------------------Modelクラス生成 (pn = 核チップ番号)
function rcs_Model.new( pn,num )
	local self = {
		ArmPower,
		Ail_R, Ail_L, Ele_R, Ele_L, Rud, Engine,

		vec,damlist,damnum,

		fli_sgn,
		stat_act,tick_act,
		isDead, tagin,tagcn, tagpos,
	}

	self.Pid_ax = Pid.new()
	self.Pid_ay = Pid.new()
	self.Pid_az = Pid.new()

	self.Sli_High = SlipVal.new()
	self.Sli_Dist = SlipVal.new()
	self.Sli_Vect = SlipVal.new()

	self.ArmChip = pn
	self.ParentChip = pn
	self.TailChip = pn + 13

	self.AilRChip = pn + 6
	self.AilLChip = pn + 3
	self.EleRChip = pn + 13
	self.EleLChip = pn + 12
	self.RudChip  = pn + 10
	self.EngChip  = pn + 1

	self.ModelNum = num	--識別用番号

	return setmetatable(self,rcs_Model_mt)
end

--------------------------------モデル用チップ生成 (pn = 親番号)
function rcs_Model.createModel( pn )
	local cn,cn2
	cn =	_ADDCHIP(pn,"ARM" ,"N", 0)
		_SET(cn, "FUELMAX", 4294967296)
		_SET(cn,"USER2",rcs_TA.USER2_Model)	--印

	cn =	_ADDCHIP(cn,"TRIM","S", 90)

	cn2=	_ADDCHIP(cn ,"CHIP","E",-87)	-- roll
	cn2=	_ADDCHIP(cn2,"TRIM","E",  0)	-- 3
	cn2=	_ADDCHIP(cn2,"CHIP","E",  0)

	cn2=	_ADDCHIP(cn ,"CHIP","E", 87)	-- roll-
	cn2=	_ADDCHIP(cn2,"TRIM","E",  0)	-- 6
	cn2=	_ADDCHIP(cn2,"CHIP","E",  0)

	cn = 	_ADDCHIP(cn ,"CHIP","S", 0)
	cn =	_ADDCHIP(cn ,"ARM" ,"S", 0)
	cn2=	_ADDCHIP(cn ,"CHIP","S", 0)	-- yaw- 10

	cn =	_ADDCHIP(cn,"TRIM","S",-90)

	cn2=	_ADDCHIP(cn,"TRIM","W",  0)	-- pitch-	12
	cn2=	_ADDCHIP(cn,"TRIM","E",  0)	-- pitch+	13

end

--------------------------------変数更新
function rcs_Model:updateModel()
	_SET(self.ArmChip	, "POWER", self.ArmPower)

	_SET(self.AilRChip	, "ANGLE",-self.Ail_R)
	_SET(self.AilLChip	, "ANGLE", self.Ail_L)

	_SET(self.EleRChip	, "ANGLE",-self.Ele_R)
	_SET(self.EleLChip	, "ANGLE", self.Ele_L)

	_SET(self.RudChip	, "ANGLE",-self.Rud)
end

--------------------------------ARMの変数を上書き
function rcs_Model:updateArm(o,c)
	_SET( self.ArmChip ,"OPTION" , o)
	_SET( self.ArmChip ,"POWER"  , 0)
	_SET( self.ArmChip ,"COLOR"  , c)
end

--------------------------------ARM
function rcs_Model:Fire()
	local arm = self.ArmChip
	if ( _E( arm ) >= _OPTION( arm ) ) then
		self.ArmPower = _OPTION( arm )
		_FORCE(arm, self:getwzpos( -self.ArmPower * 1.65 , arm ) )

		return true
	end
	return false
end

--------------------------------モデルを初期化
function rcs_Model:Init()
	self.isDead = 3	--( 0:戦場 1:無力化 2:昇天 3:天国で待機中 )

	self.Ail_R, self.Ail_L = 0,0
	self.Ele_R, self.Ele_L = 0,0
	self.Rud = 0
	self.Engine = 0

	self.fli_sgn = 0
	self.vec = { 0,0,0 }
	self.damlist = { false, false,false, false,false, false, }	--core,air,ele,rud
	self.damnum  = 0,

	self.Pid_ax:init( 0,  8,1.2,0.10 ,15 )
	self.Pid_ay:init( 0,  8,2.5,0.20 ,20 )
	self.Pid_az:init( 0,  2,  1,0.05 ,20 )

	self.Sli_High:init( 0, 0, 0.5 )
	self.Sli_Dist:init( 0, 0, 0.5 )
	self.Sli_Vect:init( 0, 1, 0.01 )

	self:setStat( 0 )
	self:initTarget()
	self:updateArm(0,0)
	self:updateModel()
end

function rcs_Model:Remove()
	local cn = self.ParentChip

	_RESET(cn)
	_WARP(cn,0,100000,0)	--高度100000m地点に保管
	_DIRECT(cn,0,0,0)
	_ENERVATE(cn)
end

----天空で保管
function rcs_Model:OnFrame_Init()
	local cn
	cn = self.ParentChip

	if (_Y(cn) < 100000 - 0.6) then self:Remove() end
	_ENERVATE(cn)
end

--------------------------------モデル出動
function rcs_Model:SetUp( xx,yy,zz, dx,dy ,armop,armco)
	local cn
	cn = self.ParentChip

	self:updateArm( armop,armco )
	self:setStat( 0 )

	_RESET(cn)
	_WARP(cn,xx,yy,zz)
	_DIRECT(cn,dx,dy,0)
	_ENERVATE(cn)

	self.isDead = 0

	self:updateModel()
end

--------------------------------モデルは星になった
function rcs_Model:Dead()
	if (self.isDead == 0) then
		self.tick_act = 0
		self.isDead = 1

		self.ArmPower = 0
		self:updateModel()
	end
end

--------------------------------ターゲットの座標をゲッツ
function rcs_Model:getTargetPos()
	if ( self.tagin ) then
		return (self.tagin):getPos2()
	elseif ( self.tagcn ) then
		return _X(self.tagcn), _Y(self.tagcn), _Z(self.tagcn)
	end
	return 0,-100000,0
end
function rcs_Model:initTarget()
	self.tagin, self.tagcn = nil,nil
	self.tagpos = {0,0,0}
end
function rcs_Model:flagTarget()
	return self.tagin or self.tagcn
end
function rcs_Model:searchTarget()
	self:initTarget()
	self.tagcn,self.tagin = searchTarget( self.ArmChip )
	if ( self:flagTarget() ) then
		self.tagpos = { self:getTargetPos() }
		return true
	end
	return false
end

function rcs_Model:checkTarget()
	if ( (self.tagcn and not checkTarget( self.tagcn ) ) or
		(self.tagin and (self.tagin):getVal(1) ~= 1 and not (self.tagin):isUse() ) ) then
		return false
	end
	return true
end

--------------------------------モデル用 OnFrame
function rcs_Model:OnFrame()
	if     (self.isDead == 1) then self:OnFrame_Die() return
	elseif (self.isDead == 2) then self:Init()	self:Remove() return
	elseif (self.isDead == 3) then self:OnFrame_Init() return
	end

	self.ArmPower = 0

	local arm,num,tcn, damflag
	num = self.ModelNum
	arm = self.ArmChip
	damflag = false	--破損検知

	do	--act
		self.tick_act = self.tick_act + 1

		if ( math.mod(self.tick_act, 4) ) then
			damflag = self:checkDamage()
		end

		if ( self:checkDie() ) then
			addScore( 1 )
			self:Dead()
			return
		end

		if ( not self:checkTarget() ) then
			self:setStat( 1 )
			self:initTarget()
		end

		if (self.stat_act == 0 or self.stat_act == 1) then	--旋回 / 離脱
			local i,d, shi,sdi,tar,ldi,curl
			local sp,mp,cv = { _X(arm),_Y(arm),_Z(arm), }, { 0,0,0, }, { 0,0,0,}

			tar = rcs_TA.FieldPost
			shi = rcs_TA.Move_High + self.Sli_High:update()
			sdi = rcs_TA.Move_Dist + self.Sli_Dist:update()

			----
			d = 0
			for i=1,3 do	mp[i] = sp[i] - tar[i]	d = d + mp[i]^2	end

			----
			if (d > 1^2) then

				mp[2] = shi + tar[2]

				d = math.sqrt( mp[1]^2 + mp[3]^2 )
				ldi = d + math.limit( sdi - d, 30,-30 )

				mp[1],mp[3] = mp[1] / d * sdi, mp[3] / d * sdi
				cv[1],cv[3] = -mp[3] / d,mp[1] / d
				curl = 30

				fli_sgn = math.sgn( _ZX(arm) * (tar[3] + mp[3]) - _ZZ(arm) * (tar[1] + mp[1]) )

				if ( self.stat_act == 1 ) then
					local xx,zz
					xx,zz = math.coll_C_to_L(	sp[1],sp[3],
									sp[1] - _ZX(arm) * sdi*4,sp[3] - _ZZ(arm) * sdi*4,
									tar[1],tar[3], sdi+100 )
					if (xx) then
						mp[2] = mp[2] + 30
						mp[1],mp[3] = xx,zz
						curl = 0
					end
				end

				for i=1,3 do	self.vec[i] = mp[i] + cv[i] * curl * fli_sgn	end

			end
			--_MOVE3D(0,0,0)
			--_LINE3D(self.vec[1],self.vec[2],self.vec[3])
			if ( self.stat_act == 0 and math.mod( self.tick_act + 30*3, 30*2 ) == 0 ) then
				self.Sli_High:set( math.random2( 30) )
				self.Sli_Dist:set( math.random2( 30) )
			end

			--out(self.ModelNum + 2, _VZ(arm) * 3.6 )

			if ( rcs_TA.AttackFlag and self.damnum >= 3 ) then
				if ( self:searchTarget() ) then
					self.Sli_Vect:set( 1 + 0.2 )
					self:setStat( 2 )
				else
					self:breakModel()
				end

			elseif ( self.stat_act == 0 ) then
				if ( self.tick_act >= rcs_TA.AttackTick + 30 and rcs_TA.ShootTick <= 0) then
					if ( rcs_TA.AttackFlag and self:searchTarget() ) then
						self.Sli_Vect:set( 1 + math.random2(0.2) )
						self:setStat( 2 )
					else
						self:setStat( 0 )
					end
				end

			elseif ( self.tick_act >= 30*2 and ( (d >= sdi - 1 and d <= sdi + 50) or self.tick_act >= 30*4 ) ) then
				self:setStat( 0 )

			end

		elseif ( self.stat_act == 2 ) then	--攻撃(2)
			if (self.tagcn) then	out(1,"!!")	end

			local tx,ty,tz, vx,vy,vz, svx,svy,svz, k, dis,ang,ang2

			tx,ty,tz = self:getTargetPos()

			svx,svy,svz = getwpos( _VX(arm)/30,_VY(arm)/30,_VZ(arm)/30, arm )
			vx,vy,vz = tx - self.tagpos[1], ty - self.tagpos[2], tz - self.tagpos[3]

			self.tagpos = {tx,ty,tz}

			tx,ty,tz,k = Est(tx - _X(arm),ty - _Y(arm),tz - _Z(arm), vx-svx,vy-svy,vz-svz, 20)

			self.vec[1],self.vec[2],self.vec[3] = tx + _X(arm),ty + _Y(arm),tz + _Z(arm)

			tx,ty,tz = getlpos(tx,ty,tz,arm )
			dis = math.sqrt(tx^2+ty^2+tz^2)
			if (dis > 0.6) then
				ang = math.limit( math.atan2( 0.3,dis ),math.pi, rcs_TA.AttackLevel1)
				ang2= math.abs( math.atan2( math.len2(tx,ty),-tz ) )
				if ( ang2 < ang ) then	self:Fire()	end
			end

			if ( self.damnum >= 3 ) then
				if ( dis < 5 or (not rcs_TA.AttackFlag) ) then
					self:breakModel()
				end

			elseif ( damflag or dis < 50 or math.abs(_H(arm)) < 10 or
					self.tick_act > 30*10 or (not rcs_TA.AttackFlag) ) then	--離脱条件

					self.Sli_Vect:set( 1 + 0.2 )
					self.Sli_Dist:set( -30 )
					self.Sli_High:set( -30 )
					self:setStat( 1 )
					self:initTarget()
			end
		end

	end	--act

	if (rcs_TA.LineFlag) then
		local xx,yy,zz = _X(arm),_Y(arm),_Z(arm)
		_SETCOLOR( _COLOR(arm) )
		_MOVE3D( xx,yy-0.6,zz )
		_LINE3D( xx,yy+0.6,zz )
		_MOVE3D( xx-0.6,yy,zz )
		_LINE3D( xx+0.6,yy,zz )
		_MOVE3D( xx,yy,zz-0.6 )
		_LINE3D( xx,yy,zz+0.6 )
	end


	----move
	do
		local dis,v,i,vz ,ax,ay,az, ti
		ti = self.Sli_Vect:update()

		v = { getlpos( self.vec[1] - _X(arm), self.vec[2] - _Y(arm) ,self.vec[3] - _Z(arm) , arm ) }
		vz = rcs_TA.Move_Vec * ti - (-_VZ(arm) * 3.6)

		dis = math.sqrt( v[1]^2 + v[2]^2 + v[3]^2 )

		if (dis > 0.1) then
			ax,ay = math.atan2( v[2],math.len2(v[3],v[1]) ), math.atan2( v[1],-v[3] )
			ax = math.limit( ax,math.pi/4,-math.pi/4 )
			ay = math.limit( ay,math.pi/4,-math.pi/4 )
			az = math.limit(-ay / 4,math.pi/4,-math.pi/4 ) + _AZ(arm) * 0.2
		else
			ax,ay,az = 0,0,0
		end

		local ro,pi,ya
		ro = math.limit( math.deg(self.Pid_az:get( az )) ,20,-20)
		pi = math.limit( math.deg(self.Pid_ax:get( ax )) ,20,-20)
		ya = math.limit( math.deg(self.Pid_ay:get( ay )) ,30,-30)

		self.Ail_R = math.step( self.Ail_R,  ro - pi / 2, 5)
		self.Ail_L = math.step( self.Ail_L, -ro - pi / 2, 5)
		self.Ele_R = math.step( self.Ele_R, pi + ro / 2, 5)
		self.Ele_L = math.step( self.Ele_L, pi - ro / 2, 5)
		self.Rud = math.step( self.Rud, ya, 5)

		self.Engine = math.limit( vz * 5000 ,100000,-100000)
	end

	_FORCE(arm, self:getwzpos( -self.Engine * 1.65 , self.EngChip ) )
	self:updateModel()
end

----
function rcs_Model:setStat( ac , ti )
	self.stat_act = ac and ac or 0
	self.tick_act = ti and ti or 0
end

function rcs_Model:breakModel()
	local i,d = 0,0
	for i = self.ParentChip, self.TailChip do
		d = _BYE(i)
	end

	self.damlist[1] = true
end

----[ 無力化判定 ]
function rcs_Model:checkDie()
	return (
			self.damlist[1] or self.damnum >= 4 or _Y(self.ParentChip) < 0 or
			_GETHIT(self.ParentChip+1, "LAND") ~= 0
		)
end

function rcs_Model:checkDamage()
	local pn = self.ParentChip
	self.damlist[1] = (_T(pn) <= 0)
	self.damlist[2] = ( _TOP( self.AilRChip ) ~= pn )
	self.damlist[3] = ( _TOP( self.AilLChip ) ~= pn )
	self.damlist[4] = ( _TOP( self.EleRChip ) ~= pn )
	self.damlist[5] = ( _TOP( self.EleLChip ) ~= pn )
	self.damlist[6] = ( _TOP( self.RudChip  ) ~= pn )

	local i,d,f = 0,0,false
	for i=1,6 do	d = d + (self.damlist[i] and 1 or 0)	end

	f = (self.damnum < d)
	self.damnum = d

	return f
end

--------------------------------派手に吹っ飛ぶ
function rcs_Model:OnFrame_Die()
	if (self.tick_act == 0) then
		self:breakModel()

	elseif (self.tick_act >= 90) then
		self.isDead = 2
	end

	self.tick_act = self.tick_act + 1
end

--------------------------------
function rcs_Model:getwzpos( lz,cn )
	return _ZX(cn)*lz, _ZY(cn)*lz, _ZZ(cn)*lz
end

--------------------[  SlipVal  ]-------------------
SlipVal = {}
SlipVal_mt = { __index=SlipVal }

function SlipVal.new( de, se, st )
	tmp = {}
	tmp.val_v, tmp.set_v, tmp.ste_v = de,se,st
	return setmetatable (tmp, SlipVal_mt)
end
function SlipVal:get()	return self.val_v	end
function SlipVal:update()
	self.val_v = math.step( self.val_v, self.set_v, self.ste_v )
	return self.val_v
end
function SlipVal:set( se )	self.set_v = se	end
function SlipVal:init( de, se, st )
	self.val_v, self.set_v, self.ste_v = de,se,st
end

--------------------[  PID  ]-------------------
Pid = {}
Pid_mt = { __index=Pid }
----追加	dei:Iの初期値  lim:Iのリミッタ(nilで無限扱い)  xkp,xki,xkd:各項の係数
function Pid.new(dei,lim,xkp,xki,xkd)
	tmp = {}
	tmp.kp,tmp.ki,tmp.kd = xkp,xki,xkd		--各項の係数
	tmp.i = dei	--積分項に使う蓄積量  ※係数は掛けない
	tmp.l = lim	--↑の最大値(+-)
	return setmetatable (tmp, Pid_mt)
end
----内蔵しておく
Pid.limit = function (val,max,min)	return val>max and max or val<min and min or val	end

----Setも兼ねる
--sd == nil だったら (今回の引数 - 前回の引数bd) を微分項 とする
--でなかったら、引数sdをそのまま微分項とする
function Pid:get(sp,sd)
	local d
	self.i = self.i + sp
	if (self.l) then  self.i = Pid.limit(self.i,self.l,-self.l)	end

	if (not sd) then
		if (not self.bd) then self.bd = sp	end
		d = sp - self.bd	self.bd = sp
	else d = sd	end
	return sp * self.kp + self.i * self.ki + d * self.kd
end
----軽く初期化
function Pid:init( dei, lim,xkp,xki,xkd )
	self.kp,self.ki,self.kd = xkp,xki,xkd
	self.i,self.l = dei,lim
	if (self.bd) then	self.bd = 0	end
end
