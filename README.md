# EschaBuyer
Eschabuyer will buy all temporary escha items that are not currently in your inventory except the primeval brew item without having to slog through the menu. Please note that this addon injects packets extensively so please take that into consideration and use at you own risk. There are some notes on the risks with this addon at the bottom section of this README.

Note: This addon can soft lock windower if you use the buy command and your inventory has not yet loaded. This can happen if you load the addon right after zoning and use the buy command before your inventory has loaded.

Note: This addon will buy temp items that you have not yet unlocked, so this could result in a higher risk when using this addon.
___
### Usage notes

1. After downloading, to use eschabuyer you must first unzip the folder in your addons folder. Be sure to rename this folder to eschabuyer.

2. After you are finished with (1.), load the addon by using the following command:
    * //lua load eschabuyer

3. Get within 6 yalms of an appropriate escha npc (Affi,Dremi,Shiftrix) (Don't enter the npc menu) and you can start to buy your missing eschan temporary items. Also note that while the addon has some safeguards, one it does not have is a check on whether you have enough silt to buy your temps, so please make sure you check your silt totals before using the addon. I'm unsure of what the result would be if you attempt to use this addon without the requisite amount of silt.

    * To buy all of your missing temp items you can enter any of the following equivalent commands:
        * //eschabuyer buy
        * //eschabuyer b
        * //eb buy
        * //eb b

4. After you input one of these purchase commands you should get an estimated wait time. Don't try to run away or open the menu or input another command until you get the completion message! If you don't get the completion message in a timely manner you may have soft locked and need to hard terminate your windower program.

5. There are two different delays you have a choice to set if you feel either is either too fast or too slow. There is a start delay that indicates the time it takes to start buying items and a normal delay which is the delay between buying items once that process starts. You can read more about this in the risks section of this document.

   * The following equivalent commands are used to change start delay values to 3 seconds:
      * //eb startdelay 3
      * //eb sd 3
      * //eschabuyer startdelay 3
      * //eschabuyer sd 3

   * The following equivalent commands are used to change regular delay values to 1 second:
      * //eb delay 1
      * //eb d 1
      * //eschabuyer delay 1
      * //eschabuyer d 1

6. There is also a feature that prints item names as they are bought. This messaging option is by default turned on but can be toggled off and on with the following equivalent commands:
   * //eschabuyer msg
   * //eschabuyer message
   * //eb msg
   * //eb message

7. You can save your starting delay, delay, and message toggle values so they load automatically next time you load the addon using the save command. If you use multiple characters and want to save these values globally use the saveall command.

   * The following are equivalent ways of using the save command:
      * //eschabuyer save
      * //eb save
      * //eschabuyer s
      * //eb s

   * The following are equivalent ways of using the saveall command:
      * //eschabuyer saveall
      * //eb saveall
      * //eschabuyer sa
      * //eb sa

8. If you ever forget these commands there is a help command that will list them:
   * //eb help
   * //eb h
   * //eschabuyer help
   * //eschabuyer h

___

### Commands
   * help|h Display all valid commands.   
   * reload|r Reload cellbuyer.   
   * unload|u Unload cellbuyer.   
   * buy|b Buy all temporary items you do not have, excluding brew.   
   * delay|d <seconds> Change the time it takes to buy one stack of cells of an npc in seconds. Default is 1 second, minimum value is 0.2   
   * startdelay|sd <seconds> Change the time it takes to buy one stack of cells of an npc in seconds. Default is 1 second, minimum value is 0
   * msg|message Toggle whether to show what items you are buying in chat. Shows by default.   
   * save|s Save your current delay,startdelay,messageToggle values for future use of cellbuyer.   
   * saveall|sa  Save your current delay,startdelay,messageToggle values globally, useful for those that use multiple characters.   

___

### Warnings

There are some things to keep in mind when setting your delay values. The first is that it takes me about 10 seconds to manually buy the first temp item from the point of targetting the relevant npc through navigating the menu. It takes me about 8 seconds to manually buy one item after buying another. It takes about 3 seconds to even be able to interact with the escha npc menu. Hopefully this explains the choice for the default delay values. For the start delay value you can probably start to look suspicious if you change this value below 10 seconds, and yet even more suspicious if you set it under 3 seconds. The minimum settable value for the start delay is 0 seconds. Similarly consider that you will likely look suspicious if you set the delay value under 8 seconds. The lowest purchase delay value you can set for this addon is 0.2 seconds.


Relative to the cellbuyer addon there is a risk difference with eschabuyer that doesn't exist with cellbuyer. There are some automated outgoing dialog choice packets (outgoing 0x05B) that occur while manually navigating the eschan npc menu that don't occur when navigating the voidwatch npc menu. The way we inject dialog packets in the eschabuyer addon certainly changes the normal order of those automated outgoing packets. So once again please consider these things before using this addon.


If you do decide to use this addon, please ENJOY!
