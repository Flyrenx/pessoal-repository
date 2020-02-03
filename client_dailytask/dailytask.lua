local _parseOpcode
local missionListWindow 
local dailyTasksOpcode = 57

function init()
	missionListWindow = g_ui.displayUI('dailytask')
	missionListWindow:hide()
	
	connect(g_game, { onLogout = hide }) 
 	connect(g_game, { onGameEnd = hide })

	g_game.handleExtendedOpcode(dailyTasksOpcode, _parseOpcode)
	missionListWindow:setup()
end

function terminate()
	disconnect(g_game, { onLogout = hide }) 
 	disconnect(g_game, { onGameEnd = hide })

	g_game.unhandleExtendedOpcode(dailyTasksOpcode)
	missionListWindow:destroy()
end

function _parseOpcode(action, data)
		if action == 'open' then
			print('mostrando')
			show()
		end
		if action == 'missionList' then
			local mission = data
			for i=1, #mission do
					local mission = mission[i]
					missionList = g_ui.createWidget('missionList', missionListWindow)
					missionList:setId('missionList'..i)
					--taskNpc
					local outfitCreatureBox = missionList:getChildById('outfitCreatureBox')
					outfitCreatureBox:setOutfit(mission.outfit)

					--taskTitle
					local titleWidget = missionList:getChildById('titleTask')
					titleWidget:setText(mission.task.title)

					--taskDescription
					local descriptionWidget = missionList:getChildById('descriptionTask')
					descriptionWidget:setText(mission.task.description)

					local taskContent = g_ui.createWidget('taskContent', missionList)

					--taskContent
					local tags = {}
					for tag, missionContent in pairs(mission.task.types) do
							if tag == 'Kill' then
								for i = 1, #mission.task[tag].count do
									local widgetKill = g_ui.createWidget('kill', taskContent)

									widgetKill:setText(tag.. ': \n' ..mission.task[tag].count[i].. 'x ')
									widgetKill:setOutfit(mission.task[tag].creatureOutfit[i])
									print(mission.task[tag].count[i].. 'x ' ..mission.task[tag].creatureName[i])
									widgetKill:setTooltip(mission.task[tag].count[i].. 'x ' ..mission.task[tag].creatureName[i])
								end

							elseif tag == 'Drop' then
								for i = 1, #mission.task[tag].count do
									local widgetDrop = g_ui.createWidget('drop', taskContent)

									widgetDrop:setText(tag.. ': \n' ..mission.task[tag].count[i].. 'x ')
									widgetDrop:setItemId(mission.task[tag].items[i].itemIdClient)
									print(mission.task[tag].count[i].. 'x ' ..mission.task[tag].items[i].itemName)
									widgetDrop:setTooltip(mission.task[tag].count[i].. 'x ' ..mission.task[tag].items[i].itemName)
								end
							end

					end
						--[[
						if tag == 'Find' then
							for i = 1, #mission.task[tag].count do

								local widgetFind = widget:getChildById('creatureTask')
								widgetFind:setOutfit(mission.task[tag].creatureOutfit[i])
								widgetFind:setTooltip(mission.task[tag].count[i].. 'x ' ..mission.task[tag].creatureName[i])
							end

						elseif tag == 'Pick' then
							for i = 1, #mission.task[tag].count do


								local widgetCollect = widget:getChildById('itemTask')
								widgetCollect:setItemId(mission.task[tag].items[i].itemIdClient)
								widgetCollect:setTooltip(mission.task[tag].count[i].. 'x ' ..mission.task[tag].items[i].itemName)
							end

						end
						]]

						--taskReward
						local rewardWidget = missionList:getChildById('rewardTask')
						rewardWidget:setTooltip('Rewards')

						local itemWidget = missionList:getChildById('rewardItems')
						itemWidget:setItemId(mission.task.reward.idClient)
						itemWidget:setText(mission.task.rewardCount.. 'x ')
						itemWidget:setTooltip(mission.task.rewardCount..'x daily token')

						--accept/claim/abandon

						local acceptButton = missionList:getChildById('acceptButton')
						local claimButton = missionList:getChildById('claimButton')
						local abandonButton = missionList:getChildById('abandonButton')
						claimButton:setVisible(false)
						abandonButton:setVisible(false)

						mission.id = i
						missionList.missionPack = mission

						local yesAcceptCallback = function()
									g_game.sendOpcode(57 , 'accept', acceptButton:getParent().missionPack) 
									acceptButton:setVisible(false)
									claimButton:setVisible(true)
									abandonButton:setVisible(true)
									acceptWindow:destroy()
									acceptWindow = nil
								end

						local noAcceptCallback = function() acceptWindow:destroy() acceptWindow = nil end

						local yesAbandonCallback = function()
							g_game.sendOpcode(57 , 'abandon', abandonButton:getParent().missionPack) 
							acceptButton:setVisible(true)
							claimButton:setVisible(false)
							abandonButton:setVisible(false)
							abandonWindow:destroy()
							abandonWindow = nil
						end

						local noAbandonCallback = function() abandonWindow:destroy() abandonWindow = nil end

						acceptButton.onClick = function(self)
							acceptWindow = displayGeneralBox(tr('Mission'), tr('You want accept ' ..mission.task.title.. ' mission ?'),
								{{ text=tr('Yes'), callback=yesAcceptCallback },
								{ text=tr('No'), callback=noAcceptCallback },
								anchor=AnchorHorizontalCenter}, yesAcceptCallback, noAcceptCallback)
						end

						claimButton.onClick = function(self)
							g_game.sendOpcode(57 , 'claim', self:getParent().missionPack) 
						end

						abandonButton.onClick = function(self, acceptButton, claimButton)
							abandonWindow = displayGeneralBox(tr('Mission'), tr('You want abandon ' ..mission.task.title.. ' mission ?'),
								{{ text=tr('Yes'), callback=yesAbandonCallback },
								{ text=tr('No'), callback=noAbandonCallback },
								anchor=AnchorHorizontalCenter}, yesAbandonCallback, noAbandonCallback)
						end
					end 
		end
		if action == 'haveMission' then
			if data[1] == true then
				local mission = missionListWindow:getChildById('missionList'..data[2])
				local acceptButton = mission:getChildById('acceptButton')
				local claimButton = mission:getChildById('claimButton')
				local abandonButton = mission:getChildById('abandonButton')
				abandonButton:setVisible(false)
				acceptButton:setVisible(true)
				claimButton:setVisible(false)
			end
		end
		if action == 'haveFinished' then
			if data[1] == true then
				local mission = missionListWindow:getChildById('missionList'..data[2])
				local claimButton = mission:getChildById('claimButton')
				local abandonButton = mission:getChildById('abandonButton')
				claimButton:setVisible(false)
				abandonButton:setVisible(false)
			end
		end
end

function show()
	missionListWindow:show()
	missionListWindow:raise()
	missionListWindow:focus()
end

function hide()
	if missionListWindow:isVisible() then
		missionListWindow:hide()
	end
end

function toggle()
	print('enviado requisito de lista rank D')
	g_game.sendOpcode(dailyTasksOpcode, 'requestRankDList')
end

function update()
	g_game.sendOpcode(dailyTasksOpcode, 'update')
end
