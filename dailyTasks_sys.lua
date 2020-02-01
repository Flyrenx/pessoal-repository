print('>> Loading daily tasks system.')
dofile('data/lib/daily_tasks/dailyTasks_list.lua')

dailyTasks = {}
dailyTasks.__index = dailyTasks

local maxTask = 5
local taskStorage = 20000
local reward = {[1] = {name = 'daily token', idClient = 12409, idServer = 12660},
				[2] = {name = 'daily token', idClient = 12409, idServer = 12660},
}

local taskDescription = {--Title, Description, looktype/itemIdClient,
	{'Kill Wolfs', 'I need you to kill some wolves and get these items.',
		{['Kill'] = {name={'wolf'}, looktype={27}}, ['Drop'] = {name={'wolf paw'}, idClient = {5897}, idServer = {5897} }}
	},

	{'Furious Toad', "There are crazy frogs in the lake, could you kill them for me?",
		{['Kill'] = {name={'toad'}, looktype={222}}, ['Drop'] = {name={'poisonous slime'}, idClient = {9640}, idServer = {10556} }}
	},

	{'Sewers in Konoha', 'Below Konoha there are several monsters, eliminate them for the good of population.',
		{['Kill'] = {name={'spider', 'bat'}, looktype={30, 122}}}
	},

	{'Boar is Delicious', 'I need boar items.',
		{['Kill'] = {name={'boar'}, looktype={765}}, ['Drop'] = {name={'meat'}, idClient = {9373}, idServer = {10290} }}
	},

	{'Konoha Culinary', "I'm with special guests at home, could you get these items for me?",
		{['Drop'] = {name={'crab meat', 'terramite head'}, idClient = {10272, 10452}, idServer = {11183, 11436} }}
	},

	{'Pick Carrot', 'I need carrots for some delicious soup but these bloody salamanders,boars and bats are destroying them all.',
		{['Kill'] = {name={'salamander', 'bat', 'boar'}, looktype={798, 122, 765}}, ['Drop'] = {name={'carrot'}, idClient = {3250}, idServer = {2684} }}
	},
}

local taskCount = {
	['D'] = {['Kill'] = {50, 100}, ['Drop'] = {10, 20}, ['Find'] = {1, 1}, ['Pick'] = {10, 20}, ['Reward'] = {1, 2}},
	['C'] = 1,
	['B'] = 2,
	['A'] = 3,
	['S'] = 4,
}


function generateOutfit()
	local npcLooktypes = {652,660,661,662,665,666,668,669,670,803,804,805, 806, 807, 808}
	local colors = {1, 2}

	local head =  math.random(1, #colors)
	local body = math.random(1, #colors)
	local legs = math.random(1, #colors)
	local feet = math.random(1, #colors)

	local looktype = npcLooktypes[math.random(1, #npcLooktypes)]

	local outfit = {type = looktype, head = 2, body = 3, legs = 4, feet = 5, auxType = 1, addons = 0}

	return outfit
end

function generateTask(rank)
	local task = {}
	local mission = taskDescription[math.random(1, #taskDescription)]

	task.title = mission[1]
	task.description = mission[2]
	task.types = mission[3]

	task.reward = reward[math.random(1, #reward)]
	task.rewardCount = math.random(taskCount[rank]['Reward'][1], taskCount[rank]['Reward'][2])

	for tag, missionContent in pairs(task.types) do
		task[tag] = {}
		task[tag].count = {}
		for i = 1, #missionContent.name do
			task[tag].count[i] = math.random(taskCount[rank][tag][1], taskCount[rank][tag][2])
		end
	end


	for tag, missionContent in pairs(task.types) do
		if tag == 'Kill' then
			task[tag].creatureName = {}
			task[tag].creatureOutfit = {}
			for i = 1, #missionContent.name do
				local creatureName = missionContent.name[i]
				local creatureOutfit = missionContent.looktype[i]
				task[tag].creatureName[i] = creatureName
				task[tag].creatureOutfit[i] = {type = creatureOutfit}
			end
		elseif tag == 'Find' then
			task[tag].creatureName = {}
			task[tag].creatureOutfit = {}
			for i = 1, #missionContent.name do
				local creatureName = missionContent.name[i]
				local creatureOutfit = missionContent.looktype[i]
				task[tag].creatureName[i] = creatureName
				task[tag].creatureOutfit[i] = {type = creatureOutfit}
			end
		elseif tag == 'Drop' then
			task[tag].items = {}
			for i = 1, #missionContent.name do
				local itemName = missionContent.name[i]
				local itemIdClient = missionContent.idClient[i]
				local itemIdServer = missionContent.idServer[i]
				task[tag].items[i] = {itemName = itemName, itemIdClient = itemIdClient, itemIdServer = itemIdServer}
			end
		elseif tag == 'Pick' then
			task[tag].items = {}
			for i = 1, #missionContent.name do
				local itemName = missionContent.name[i]
				local itemIdClient = missionContent.idClient[i]
				local itemIdServer = missionContent.idServer[i]
				task[tag].items[i] = {itemName = itemName, itemIdClient = itemIdClient, itemIdServer = itemIdServer}
			end
		end
	end

	return task
end

function generateReward()
end

function sendMissionList(player, rank)
	local missions = {}
	for i=1, maxTask do
		table.insert(missions, {outfit = generateOutfit(), task = generateTask(rank)})
	end

	player:sendOpcode(OPCODE_DAILY_TASKS, 'missionList', missions)
end

function dailyTasksParseOpcode(player, packet)
	local action = packet.action
	local data = packet.data

	if action == 'requestRankDList' then
		local rank = 'D'
		sendMissionList(player, rank)

	elseif action == 'update' then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 'Update futuro,de seu feedback no discord')

	elseif action == 'accept' then
		if hasTask(player, task) then
			player:sendTextMessage(MESSAGE_INFO_DESCR, 'You need to finish your task first.')
			player:sendOpcode(OPCODE_DAILY_TASKS, 'haveMission', {true, data.id, data.missionList})
			return false
		end

		task = data.task
		local storages = 0

		player:setStorageValue(taskStorage, 0)
		player:sendTextMessage(MESSAGE_INFO_DESCR, 'You started ' ..task.title.. ' mission')

		for tag, value in pairs(task.types) do
			task[tag].storage = {}
			for i,v in pairs(task[tag].count) do
				storages = storages + 1
				task[tag].storage[i] = taskStorage + storages
				player:setStorageValue(taskStorage + storages, 0)
			end
		end

	elseif action == 'claim' then

		if completedTask(player, task) then
			player:addItem(task.reward.idServer, task.rewardCount)
			player:sendTextMessage(MESSAGE_INFO_DESCR, 'Voce ganhou ' ..task.rewardCount.. 'x ' ..task.reward.name.. ' por completar a task')
			for i = 0, 5 do
				player:setStorageValue(taskStorage + i, -1)
			end
			player:sendOpcode(OPCODE_DAILY_TASKS, 'haveFinished', {true, data.id, data.missionList})
		end

	elseif action == 'abandon' then
		for i = 0, 5 do
			player:setStorageValue(taskStorage + i, -1)
		end
		player:sendTextMessage(MESSAGE_INFO_DESCR, 'You abandoned ' ..task.title.. ' mission')

	end
end

function hasTask(player, task) 
	if player:getStorageValue(taskStorage) == 0 then
		return true
	end
	return false
end

function getActivatedTask(player, task)
	if player:getStorageValue(taskStorage) == -1 then
		return false
	end
	return task
end

function haveDropItems(player, task)
	local activatedTask = task['Drop']
	if activatedTask then
	    for i, item in pairs(activatedTask.items) do
	        if player:getItemCount(activatedTask.items[i].itemIdServer) < activatedTask.count[i] then 
	        	player:sendTextMessage(MESSAGE_INFO_DESCR, 'You have already ' ..player:getItemCount(activatedTask.items[i].itemIdServer)
	        	.. '/' ..activatedTask.count[i].. ' ' ..activatedTask.items[i].itemName)
	        	return false
	       	end   
	    end
	else return false end

	return true
end

function haveKilled(player, task)
	local activatedTask = task['Kill']
	if activatedTask then
		for i, count in pairs(activatedTask.count) do
		    if player:getStorageValue(activatedTask.storage[i]) < count then
		    	player:sendTextMessage(MESSAGE_INFO_DESCR, 'You need kill ' ..player:getStorageValue(activatedTask.storage[i]).. 
				'/' ..count.. ' ' ..activatedTask.creatureName[i].. '')
		        return false
		    end
		end
	end

	return true
end

function completedTask(player, task)
	local activatedTask = task

	local tags = {}
	for tag, missionContent in pairs(activatedTask.types) do
		table.insert(tags, tag)

	end

	if #tags > 1 then
		if haveDropItems(player, task) and haveKilled(player, task) then
			for i, item in pairs(activatedTask['Drop'].items) do
				player:removeItem(activatedTask['Drop'].items[i].itemIdServer, activatedTask['Drop'].count[i])
			end
			return true
		end
	else
		if tags[1] == 'Kill' then
			if haveKilled(player, task) then
				return true
			end
		elseif tags[1] == 'Drop' then
			if haveDropItems(player, task) then
				for i, item in pairs(activatedTask['Drop'].items) do
					player:removeItem(activatedTask['Drop'].items[i].itemIdServer, activatedTask['Drop'].count[i])
				end
				return true
			end
		end
	end
	return false
end

function dailyTasks:onKill(player, monsterName)
	local activatedTask = getActivatedTask(player, task)['Kill']

	if activatedTask then
		for i, count in pairs(activatedTask.count) do
			if monsterName == activatedTask.creatureName[i] then
				player:setStorageValue(activatedTask.storage[i], player:getStorageValue(activatedTask.storage[i]) + 1)
				if player:getStorageValue(activatedTask.storage[i]) == count then
					player:sendTextMessage(MESSAGE_INFO_DESCR, 'You finished your task! Go back to get your reward!')
				elseif player:getStorageValue(activatedTask.storage[i]) < count then
					player:sendTextMessage(MESSAGE_INFO_DESCR, 'You already killed ' ..player:getStorageValue(activatedTask.storage[i]).. 
					'/' ..count.. ' ' ..monsterName.. ' from daily task.')
				end
			end
		end
	end

	return true
end