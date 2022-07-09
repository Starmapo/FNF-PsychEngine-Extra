local camRot = false
local camRotInd = 0

function onCreate()
	setProperty('camZooming', true)
end

function onUpdate(elapsed)
	if (camRot) then
		camRotInd = camRotInd + 1
		camera.angle = math.sin(camRotInd / 100 * 1) * 10;
	else 
		camRotInd = 0
	end
end

function onBeatHit()
	if ((curBeat >= 60 and curBeat < 116) or (curBeat >= 444 and curBeat < 500)) then
		camRot = true
	else
		camRot = false
	end

	if (curBeat == 60) or (curBeat == 116) or (curBeat == 204) or (curBeat == 300) or (curBeat == 444) then
		cameraFlash('camgame', '0xBFFFCC00', 0.5, false)
	end
end