--�l�b�g���[�N�ɂ�����V�i���I�s�������p�̊O���ݒ�t�@�C��
--�����ɂ����Ă������܂�

--��x�ɓW�J���郂�f���̐��ł��B
rcs_TA.ModelNum = 4

--���f����Arm�o�͂ł��B
rcs_TA.ModelArm = 4000

--�W�I�̎����ݒu�ɂ��Đݒ肵�܂�
-- 0 : ���ݒu
-- 1 : �S�Ō�A�܂Ƃ߂Đݒu
rcs_TA.EnemyType = 1

--�U�����Ă��邩�ǂ��������肵�܂��B
--�i�L�[�Ő؂�ւ��\
rcs_TA.AttackFlag = false

--�W�I�Ƀ��C����`�悷�邩�ǂ��������肵�܂��B
rcs_TA.LineFlag = true

--�U���̐��x��ݒ肵�܂��B
rcs_TA.AttackLevel1 = 0.1	--�傫������G�c��(rad)

--�U���̕p�x��ݒ肵�܂��B(f)
rcs_TA.AttackTick   = 30*7

--����̊�ƂȂ�ݒ�ł�
rcs_TA.Move_High = 180	--��{���x(m)
rcs_TA.Move_Dist = 250	--��{����(m)
rcs_TA.Move_Vec  = 500	--��{���x(km/h)	��200km/h ������̌��E

--�I�����C���ɑΉ�������
--�U���ΏۂɂȂ邾���ł���
rcs_TA.NetworkFlag = true

--�t�B�[���h�̊�_��ݒ肵�܂��B
--����ɉe������
rcs_TA.FieldPost = {0,0,0}

--�^�[�Q�b�g���ɂ��Ă̊֐��ł��Btrue��Ԃ��Ƃ��̃`�b�v���_���܂��B
rcs_TA.isTarget = function ( cn )
	local type = _TYPE(cn)
	return (type == 10 or type == 0)	--CORE(0)��ARM(10)��_��
end
