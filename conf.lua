--ネットワークにおけるシナリオ不整合回避用の外部設定ファイル
--すきにせっていしたまへ

--一度に展開するモデルの数です。
rcs_TA.ModelNum = 4

--モデルのArm出力です。
rcs_TA.ModelArm = 4000

--標的の自動設置について設定します
-- 0 : 即設置
-- 1 : 全滅後、まとめて設置
rcs_TA.EnemyType = 1

--攻撃してくるかどうかを決定します。
--Ｊキーで切り替え可能
rcs_TA.AttackFlag = false

--標的にラインを描画するかどうかを決定します。
rcs_TA.LineFlag = true

--攻撃の精度を設定します。
rcs_TA.AttackLevel1 = 0.1	--大きい程大雑把に(rad)

--攻撃の頻度を設定します。(f)
rcs_TA.AttackTick   = 30*7

--旋回の基準となる設定です
rcs_TA.Move_High = 180	--基本高度(m)
rcs_TA.Move_Dist = 250	--基本距離(m)
rcs_TA.Move_Vec  = 500	--基本速度(km/h)	※200km/h が制御の限界

--オンラインに対応させる
--攻撃対象になるだけですが
rcs_TA.NetworkFlag = true

--フィールドの基準点を設定します。
--旋回に影響あり
rcs_TA.FieldPost = {0,0,0}

--ターゲット候補についての関数です。trueを返すとそのチップが狙われます。
rcs_TA.isTarget = function ( cn )
	local type = _TYPE(cn)
	return (type == 10 or type == 0)	--CORE(0)とARM(10)を狙う
end
