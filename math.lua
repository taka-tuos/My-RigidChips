
math.sgn = function (x) if x < 0 then return -1 elseif x == 0 then return 0 else return 1 end end
math.random2 = function(v) return (math.random() - 0.5) * 2 * v end
math.len2 = function(v1,v2)	return math.sqrt(v1^2 + v2^2)	end
math.step = function (v,n,s)		return (v+s<n and v+s or (v-s>n and v-s or n))	end
math.limit = function (val,max,min)	return val>max and max or val<min and min or val	end
math.loop = function (val,max,min)
	while (val > max) do	val = min + (val - max)	end
	while (val < min) do	val = max + (val - min)	end
	return val
end
math.cross = function (a1,a2)	return math.sin(a1) * math.cos(a2) - math.sin(a2) * math.cos(a1)	end
math.dot   = function (a1,a2)	return math.sin(a1) * math.sin(a2) + math.cos(a2) * math.cos(a1)	end
math.rot   = function (ax,ay, rad, cx,cy)
	local co,si = math.cos(rad) ,math.sin(rad)
	cx,cy = (cx and cx or 0), (cy and cy or 0)
	return (ax-cx)*co - (ay-cy)*si + cx ,(ax-cx)*si + (ay-cy)*co + cy 
end

math.coll_C_to_L = function( sxx,syy, exx,eyy, cxx,cyy, crr )
	local sff,eff
	sff = ( ((cxx-sxx)^2 + (cyy-syy)^2) < crr^2 )	--‰~“à‚ÉŽû‚Ü‚Á‚Ä‚é‚©
	eff = ( ((cxx-exx)^2 + (cyy-eyy)^2) < crr^2 )

	if (sff and eff) then	return nil,nil	end
	if ( (not sff) and (not eff) ) then
		local sx,sy,vx1,vy1, vx2,vy2
		sx,sy   = exx - sxx, eyy - syy
		vx1,vy1 = sxx - cxx, syy - cyy
		vx2,vy2 = exx - cxx, eyy - cyy

		if ( (sx*vx1 + sy*vy1) * (sx*vx2 + sy*vy2) <= 0 ) then
			return nil,nil
		end
	end

	local a,b,c
	a = eyy - syy
	b = sxx - exx
	c = -( a*sxx + b*syy )

	local len,dis,sqr
	len = a^2 + b^2
	if (len <= 0) then	return	nil,nil	end
	dis = a*cxx + b*cyy + c

	local x1,y1, x2,y2
	sqr = math.sqrt( crr^2 - dis^2 / len ) / math.sqrt(len)

	x1 = cxx - a * (dis / len) + sqr * b
	y1 = cyy - b * (dis / len) - sqr * a
	x2 = cxx - a * (dis / len) - sqr * b
	y2 = cyy - b * (dis / len) + sqr * a

	if     (sff and not eff) then	return x2, y2
	elseif (eff and not sff) then	return x1, y1
	end
	return x1, y1
end