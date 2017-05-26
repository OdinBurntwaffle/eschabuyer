-- Copyright � 2017, Burntwaffle@Odin
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
--     * Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
--     * Neither the name of eschabuyer nor the
--       names of its contributors may be used to endorse or promote products
--       derived from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL Burntwaffle@Odin BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

_addon.name = 'EschaBuyer'
_addon.author = 'Burntwaffle@Odin'
_addon.version = '1.0'
_addon.commands = {'eschabuyer','eb'}
_addon.language = 'english'

--TODO:See if there is a way to find a players silt amount for another safeguard.

local res = require('resources')
local packets = require('packets')
local config = require('config')
require('functions')

require('tables')
local defaults = {}
defaults.delay = 1
defaults.startDelay = 3
defaults.showItemsBeingBought = true

settings = config.load('data/settings.xml',defaults)

local playerIndex = windower.ffxi.get_player().index

local valid_zones = T{"Escha - Zi'Tah","Escha - Ru'Aun","Reisenjima"}
local valid_zone_IDs = T{288,289,291}

local validNPCInfo = T{
   [288] = {['Target'] = 17957447,['Target Index'] = 583,['Menu ID'] = 9701},--Escha Zi'tah, Affi
   [289] = {['Target'] = 17961711,['Target Index'] = 751,['Menu ID'] = 9701},--Escha - Ru'Aun, Dremi
   [291] = {['Target'] = 17969973,['Target Index'] = 821,['Menu ID'] = 9701},--Reisenjima, Shiftrix
}
local valid_npc_name = T{'Affi','Dremi','Shiftrix'}

--EXIT values for 0x5b packet for all 3 escha npcs
local EXIT_OPTION = 0
local EXIT_UNKNOWN_1 = 16384

local TEMP_BAG_NUM = 3

--Some default packets,These are sent initially after an incoming 0x34 menu packet and other places depending on state of the menu
--And exit menu packet
option14Packet = {}
option8Packet = {}
option9Packet = {}
exitPacket = {}
buyTempPacket = {}


missingTempIDs = T{}
everyEschaTemp = require('allEschaTemps')

local zoneHasLoaded = true
busy = false
cellColor = 0
stacks = 0
counter = 1
purchaseQueue = {}

windower.register_event('load',function()
   makeDefaultPackets()
end)

windower.register_event('incoming chunk', function(id,data)
   if id == 0x00A then--On a zone in update default packets if zoning into an escha zone.
      makeDefaultPackets()
   end

   if id == 0x00A or id == 0x00B then
      zoneHasLoaded = false
   end

   if id == 0x034 and busy then
      startBuyingTemps()
      return true
   end

   if id == 0x01D then
      if not zoneHasLoaded then
			zoneHasLoaded = true
		end
   end

end)

windower.register_event('login',function(name)
   zoneHasLoaded = false
end)

windower.register_event('outgoing chunk',function(id,data)
   if id == 0x05B--[[ or id == 0x01A]] then --Dialog choice
       local pkt = packets.parse('outgoing',data)
       if pkt then
          if pkt['Option Index'] == 0 and pkt['_unknown1'] == EXIT_UNKNOWN_1 then
             busy = false
          end
         --  windower.add_to_chat(204,'Target: ' .. pkt['Target'] .. ' Option: ' .. pkt["Option Index"] .. '  Unknown 1: ' .. pkt['_unknown1'] .. ' Target Index: ' .. pkt['Target Index'] .. ' Automated Message: ' .. tostring(pkt['Automated Message']) .. '  Unknown 2: ' .. pkt['_unknown2'] .. ' Zone: ' .. pkt['Zone'] .. ' Menu ID: ' .. pkt['Menu ID'])
       else
          windower.add_to_chat(204, 'Error')
       end
    end

end)

windower.register_event('addon command', function(inp,...)
   local input = string.lower(inp)

   if input == 'unload' or input == 'u' then
      windower.send_command('lua unload ' .. _addon.name)
   elseif input == 'reload' or input == 'r' then
      windower.send_command('lua reload ' .. _addon.name)
   elseif input == 'buy' or input == 'b' then
      buyAllTemps()
   elseif input == 'delay' or input == 'd' then
      changeDelay(arg[1])
   elseif input == 'startdelay' or input == 'sd' then
      changeStartDelay(arg[1])
   elseif input == 'msg' or input == 'message' then
      toggleMessageDisplay()
   elseif input == 'help' or input == 'h' then
      getHelpText()
   elseif input == 's' or input == 'save' then
      settings:save()
      windower.add_to_chat(204,'You saved your delay and toggleMessage value')
   elseif input == 'saveall' or input == 'sa' then
      settings:save('all')
      windower.add_to_chat(204,'You saved your global delay and global toggleMessage value.')
   end
end)

function toggleMessageDisplay()
   if settings.showItemsBeingBought then
      settings.showItemsBeingBought = false
      windower.add_to_chat(123,'As items are being purchased a message will NOT display.')
   else
      settings.showItemsBeingBought = true
      windower.add_to_chat(204,'As items are being purchased a message will display.')
   end
end

function buyAllTemps()
   if zoneHasLoaded then
      if not busy then
         --Check in correct zone
         --Check within correct distance to npc
         --Check you actually need to buy temps
         --Check currency amount to see if  buying all is possible.
         local isValidRequest = true

         if not checkClearance() or not isValidRequest then
            isValidRequest = false
            busy = false
            return false
         end

         if not getMissingTemps() or not isValidRequest then
            isValidRequest = false
            busy = false
            return false
         end

         if isValidRequest then
            --Buy Stuff
            -- windower.add_to_chat(466,'Buying Stuff')
            busy = true
            targetNPC()
         end
      else
         busy = false
         windower.add_to_chat(123,'You are still buying temps!')
      end

   else
      windower.add_to_chat(123,'Your inventory is still loading please wait to use the buy command until it fully loads!')
   end
end

function startBuyingTemps()
   if missingTempIDs:length() ~= 0 then
      for i = 1, missingTempIDs:length() do
         functions.schedule(buyTemp,((i - 1) * settings.delay) + settings.startDelay,missingTempIDs[i])
      end

      -- functions.schedule(message,((missingTempIDs:length() + 1) * settings.delay) + 1,settings.startDelay)
      functions.schedule(injectExitPacket,((missingTempIDs:length() + 1) * settings.delay) + settings.startDelay)
      functions.schedule(injectUpdatePacket,((missingTempIDs:length() + 1) * settings.delay) + settings.startDelay)
      windower.add_to_chat(466,'Starting to buy temps. Should finish in ~' .. ((missingTempIDs:length() + 1) * settings.delay) + settings.startDelay .. ' seconds.')

   else
      --TODO:maybe make an escape here
   end
end

function buyTemp(id)
   local zoneID = windower.ffxi.get_info().zone
   local targetID = validNPCInfo[zoneID]['Target']
   local targetIndex = validNPCInfo[zoneID]['Target Index']
   local menuID = validNPCInfo[zoneID]['Menu ID']

   buyTempPacket = packets.new('outgoing',0x05B)
   buyTempPacket["Target"]=targetID + 0
   buyTempPacket["Option Index"]= everyEschaTemp[id + 0].option + 0
   buyTempPacket["_unknown1"]=0
   buyTempPacket["Target Index"]=targetIndex + 0
   buyTempPacket["Automated Message"]=true
   buyTempPacket["_unknown2"]=0
   buyTempPacket["Zone"]=zoneID + 0
   buyTempPacket["Menu ID"]=menuID + 0

   if settings.showItemsBeingBought then
      windower.add_to_chat(204,'Bought: ' .. everyEschaTemp[id + 0].en)
   end

   packets.inject(buyTempPacket)
   -- packets.inject(option14Packet)
end

function injectOption9Packet()
   packets.inject(option9Packet)
end

function injectExitPacket()
   local zoneID = windower.ffxi.get_info().zone
   local targetID = validNPCInfo[zoneID]['Target']
   local targetIndex = validNPCInfo[zoneID]['Target Index']
   local menuID = validNPCInfo[zoneID]['Menu ID']

   exitPacket = packets.new('outgoing',0x05B)
   exitPacket["Target"]=targetID + 0
   exitPacket["Option Index"]=0
   exitPacket["_unknown1"]=EXIT_UNKNOWN_1 + 0
   exitPacket["Target Index"]=targetIndex + 0
   exitPacket["Automated Message"]=false
   exitPacket["_unknown2"]=0
   exitPacket["Zone"]=zoneID + 0
   exitPacket["Menu ID"]=menuID + 0

   packets.inject(exitPacket)
   busy = false
   return true
end

function injectUpdatePacket()
   local packet = packets.new('outgoing',0x016,{
      ['Target Index'] = playerIndex
   })

   packets.inject(packet)
   busy = false
   windower.add_to_chat(466,'Finished buying temps.')
   return true
end

function makeDefaultPackets()
--There appear to be 3 automated 0x5b packets on selecting affi,same for all escha NPCs
--1)OPtion:14,Unknown1:0,Automated message:true
--2)Option:8,Unknown1:0,Automated message:true
--3)Option:9,Unknow1:0,Automated message:true

   local zoneID = windower.ffxi.get_info().zone
   if valid_zones:contains(res.zones[zoneID].en) then
      local targetID = validNPCInfo[zoneID]['Target']
      local targetIndex = validNPCInfo[zoneID]['Target Index']
      local menuID = validNPCInfo[zoneID]['Menu ID']

      option14Packet = packets.new('outgoing', 0x05B)
      option14Packet["Target"]=targetID + 0
      option14Packet["Option Index"]=14
      option14Packet["_unknown1"]=0
      option14Packet["Target Index"]=targetIndex + 0
      option14Packet["Automated Message"]=true
      option14Packet["_unknown2"]=0
      option14Packet["Zone"]=zoneID + 0
      option14Packet["Menu ID"]=menuID + 0

      option8Packet = packets.new('outgoing', 0x05B)
      option8Packet["Target"]=targetID + 0
      option8Packet["Option Index"]=8
      option8Packet["_unknown1"]=0
      option8Packet["Target Index"]=targetIndex + 0
      option8Packet["Automated Message"]=true
      option8Packet["_unknown2"]=0
      option8Packet["Zone"]=zoneID + 0
      option8Packet["Menu ID"]=menuID + 0

      option9Packet = packets.new('outgoing', 0x05B)
      option9Packet["Target"]=targetID + 0
      option9Packet["Option Index"]=9
      option9Packet["_unknown1"]=0
      option9Packet["Target Index"]=targetIndex + 0
      option9Packet["Automated Message"]=true
      option9Packet["_unknown2"]=0
      option9Packet["Zone"]=zoneID + 0
      option9Packet["Menu ID"]=menuID + 0
   else

   end
end

--[[Returns true if you are missing a temp, false if you are not missing any.]]
function getMissingTemps()
   missingTempIDs = T{}
   local ownedTemps = T{}--3 is temporary bag

   for key,itemTable in pairs(windower.ffxi.get_items(TEMP_BAG_NUM)) do--3 Is  temp item bag ID
      if key ~= 'max' and key ~= 'count' and key ~= 'enabled' then
         local itemID = itemTable.id
         if itemID ~= 0 then
            ownedTemps:append(itemID)
         end
      end
   end

   for itemID,itemTable in pairs(everyEschaTemp) do
      if not ownedTemps:contains(itemID) then
         missingTempIDs:append(itemID)
      end
   end

   if missingTempIDs:length() == 0 then
      windower.add_to_chat(123,'You have all your temp items already.')
   end

   return missingTempIDs:length() ~= 0
end

function targetNPC()
   local zoneID = windower.ffxi.get_info().zone
   local targetID = validNPCInfo[zoneID]['Target']
   local targetIndex = validNPCInfo[zoneID]['Target Index']

   local activateNPCPacket = packets.new("outgoing",0x01A,{
      ['Target'] = targetID,
      ['Target Index'] = targetIndex,
      ['Category'] = 0,
      ['Param'] = 0,
      ['_unknown1'] = 0,
   })

   packets.inject(activateNPCPacket)
end

function checkClearance()
   --Check in correct zone
   --Check that there is inventory space/no dumb numbers
   --Check distance to appropriate npc is <sqrt(36)
   --TODO:Check have available currency.
   local isCleared = true

   local zoneID = tonumber(windower.ffxi.get_info().zone)

   if not valid_zones:contains(res.zones[zoneID].en) then
      busy = false
      isCleared = false
      windower.add_to_chat(123,'Not in an escha zone!')
   elseif getDistanceToNPC(targetNPC) >  6 then
      isCleared = false
      busy = false
      windower.add_to_chat(123,'Not within 6 yalms of the voidwatch npc in this zone!')
   end

   return isCleared
end

--Make sure within 6 yalms of target npc
function getDistanceToNPC()
   local zoneID = tonumber(windower.ffxi.get_info().zone)
   local target = windower.ffxi.get_mob_by_id(validNPCInfo[zoneID]['Target'])
   if target then
      return math.sqrt(target.distance)
   else
      return 9001
   end
end

function changeDelay(delayInSeconds)
   if tonumber(delayInSeconds) > 0.2 then
      settings.delay = tonumber(delayInSeconds)
      windower.add_to_chat(204,'Delay set to ' .. delayInSeconds)
   else
      settings.delay = 0.2
      windower.add_to_chat(204,'Delay set to 0.2')
   end
end

function changeStartDelay(delayInSeconds)
   if tonumber(delayInSeconds) > 0 then
      settings.startDelay = tonumber(delayInSeconds)
      windower.add_to_chat(204,'Start delay set to ' .. delayInSeconds)
   else
      settings.startDelay = 0
      windower.add_to_chat(204,'Start delay set to 0')
   end
end

function getHelpText()
   windower.add_to_chat(204,string.format('Addon: %s Version: %s command listing', _addon.name, _addon.version))
   windower.add_to_chat(204,'   help|h Display all valid commands.')
   windower.add_to_chat(204,'   reload|r Reload cellbuyer.')
   windower.add_to_chat(204,'   unload|u Unload cellbuyer.')
   windower.add_to_chat(204,'   buy|b Buy all temporary items you do not have, excluding brew.')
   windower.add_to_chat(204,'   delay|d <seconds> Change the time it takes to buy one stack of cells of an npc in seconds. Default is 1 second, minimum value is 0.2')
   windower.add_to_chat(204,'   startdelay|sd <seconds> Change the time it takes to buy one stack of cells of an npc in seconds. Default is 1 second, minimum value is 0')
   windower.add_to_chat(204,'   msg|message Toggle whether to show what items you are buying in chat. Shows by default.')
   windower.add_to_chat(204,'   save|s Save your current delay,startdelay,messageToggle values for future use of cellbuyer.')
   windower.add_to_chat(204,'   saveall|sa  Save your current delay,startdelay,messageToggle values globally, useful for those that use multiple characters.')
end
