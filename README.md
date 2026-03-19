# SimpleDataStores Lite Edition (ROBLOX PACKAGE)
Hello! Thanks for choosing TaylorDev_RBLX's SimpleDataStores module. The easiest way to save and retrieve all diffrent types of player data! This package is designed for people who need an easy and effortless way to set up and manage player data. This is the lite version which is designed for people who are less advanced while not limiting advanced features. The pro edition is coming soon!

---

### What is this package?
SimpleDataStores is a data stores package that aims on making player data stores easier and more efficient to handle without needing to understand how to code. SimpleDataStores has both standard and advanced capabilites from being able to set up and save leaderstats (public) and hidden player data from values to folders within seconds to being able to attach a Module Script to redirect the saving and retrieving processes. All within one package, and that's not even half of it!

### How to Set Up:
1. Download either the package (Additional ways to do so: [Creator Store Model](https://create.roblox.com/store/asset/102645430267245/SimpleDataStores-Package-V7) or [Documentations Latest Versions](https://taylordev.gitbook.io/simpledatastores-rblx/newest-fix/latest-version) )
2. Add this to your Roblox Studio project
3. Change PublicPlayerData to have values that you want displayed on the leaderstats (player list)
4. Change HiddenPlayerData to have values or folder's that you want hidden and accessible within the player instance
5. Feel free to add tags to data set's if they need saving process changes
6. Adjust the settings to your liking
7. You're fully set up and ready! It was that easy.

### Key Features and Settings:
- **Data Types** - Public (leaderstats) and Hidden player data capabilities
- **Tools/Backpack Saving** - Player backpack / tools saving which can be manually set or automatic
- **Data Manipulation Tags** - Use tags to change the data saving and retrieving processes such as SDS_NoDeathSave which resets a data type to the default when they die, SDS_NoRejoinSave which will set data to the default when a player leaves and even SDS_SaveOnWorldRelocation which will continue the saving process even when the data type is outside of the player.
- **Serialisation Saving Customisations** - Serialize and save custom instance properties with ease either manually set or automatic
- **Economy Tracking** - Enable Economy tracking which uses Roblox Analytics Service to give you statistics for player progression
- **Custom Data Module** - Allows you to attach a module script to the package to redirect the saving and retrieving process to your own logic and customisation requirements (This feature is considered to be for advanced users only)
- **Data Loss Prevention** - Includes compulsory cashe data saves, outdated version prevention to abort and kick players who go into a previous place version and even data saving retrying which is fully customisable in how long the system should wait and how many times it should attempt until it should stop.

### Package Aim:
- To be as simplified and easy to use as possible to best suit both beginners and advanced developers who want to speed up development
- Include valuable and unique capabilities that can best fit a wide variety of game types
- Make setting up player data extremely efficient. Instead of taking hours, this package can do that in seconds
- Make player data not seem so scary and challenging for developers of all skill set's

### Roadmap:
* **Moveable API modules - Pro-Edition v1** - Custom API endpoints built in that any script will be able to connect to and can be moved anywhere in the game space while still having direct connections with the main systems

* **Data Methods - Pro-Edition v1** - Everyone has their own preferred method os storing player data within their games, let's onboard that! You'll be able to choose between the default instence storage, player instence attributes or even lua tables with a moveable API module

* **Store value changes - Pro-Edition v1** - Currently, the system saves player data (mostly stored in script until player leaves) either by auto-saving, player dies or player leaves. This change will make it so that player data is stored everytime it's values, and ascendents updates.
---

### MIT License

SimpleDataStores Package
Copyright (c) 2025 TaylorDev_RBLX

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
