local cookie
if lOS and lOS.userID then
    cookie = {Cookie=lOS.userID}
end

local function printUsage()
    local programName = arg[0] or fs.getName(shell.getRunningProgram())
    print("Usages:")
    print(programName .. " put <path> <project name> [listing]")
    print(programName .. " get <project name> <path>")
    print(programName .. " run <project name> <arguments>")
end

local tArgs = { ... }
if #tArgs < 2 then
    printUsage()
    return
end

if not http then
    printError("LevelStore requires the http API")
    printError("Set http.enabled to true in CC: Tweaked's config")
    return
end

local function fread(file)
    local f = fs.open(file,"r")
    local o = f.readAll()
    f.close()
    return o
end

local function fwrite(file,content)
    local f = fs.open(file,"w")
    f.write(content)
    f.close()
    return true
end

local hpost = http.post

local function getField(thing,fieldname)
    if string.find(thing,"<"..fieldname..">",1,true) ~= nil and string.find(thing,"</"..fieldname..">",1,true) ~= nil then
        begin = nil
        ending = nil
        trash,begin = string.find(thing,"<"..fieldname..">",1,true)
        ending,ending2 = string.find(thing,"</"..fieldname..">",begin+1,true)
        if begin ~= nil and ending ~= nil then
            return string.sub(thing,begin+1,ending-1),string.sub(thing,1,trash-1)..string.sub(thing,ending2+1,string.len(thing))
        end
    end
    return nil
end

local rType

local function download(name,pth,saveto,run)
    local f = hpost("https://os.leveloper.cc/sGet.php","path="..textutils.urlEncode(pth).."&"..rType.."="..textutils.urlEncode(name),cookie).readAll()
    if f and f ~= "409" and f ~= "403" and f ~= "401" then
    	if run then
    		return f
    	else
        	fwrite(saveto,f)
        	return true
        end
    else
        return false
    end
end


local function get(name)

    write("Connecting to LevelStore... ")

    rType = "code"
    local response, err = http.post("https://os.leveloper.cc/sGet.php","path="..textutils.urlEncode("").."&code="..textutils.urlEncode(name),cookie)

    if not response then
    	rType = "name"
    	response, err = http.post("https://os.leveloper.cc/sGet.php","path="..textutils.urlEncode("").."&name="..textutils.urlEncode(name),cookie)
    end

    if response then
    	local tree = {}
	    local folders = {}
	    local function searchFolder(folder)
	        --print("Searching folder root/"..folder)
	        local f = hpost("https://os.leveloper.cc/sGet.php","path="..textutils.urlEncode(folder).."&"..rType.."="..textutils.urlEncode(name),cookie).readAll()
	        --print(f)
	        local f2 = f
	        while true do
	            local file = nil
	            file,f = getField(f,"file")
	            if not file then
	                break
	            else
	                local name = getField(file,"name")
	                tree[#tree+1] = fs.combine(folder,name)
	                --print("Found "..fs.combine(folder,name))
	            end
	        end
	        f = f2
	        while true do
	            local file = nil
	            file,f = getField(f,"folder")
	            if not file then
	                break
	            else
	                local name = getField(file,"name")
	                --if not fs.exists(fs.combine(folder,name)) then
	                    --fs.makeDir(fs.combine(folder,name))
	                --end
	                folders[#folders+1] = fs.combine(folder,name)
	                searchFolder(fs.combine(folder,name))
	            end
	        end
	        return true
	    end
	    searchFolder("")
        print("Success.")

        return tree,folders
    else
        printError("Failed.")
        print(err)
    end
end

local sCommand = tArgs[1]
if sCommand == "put" then
	if #tArgs < 3 then
		printUsage()
		return
	end
    local listings = {"unlisted","public"}
    for t=1,#listings do
        listings[listings[t]] = true
    end
    local listing
    if tArgs[4] then
        if not listings[tArgs[4]] then
            error(tArgs[4].." is not a valid listing. Choose one of the following: "..table.concat( listings, ", "),0)
        else
            listing = tArgs[4]
        end
    end
	if not lOS.userID then
		print("Not logged in")
		print("Please have an active instance of LevelCloud running")
		return
	end


    local sFile = tArgs[2]
    local sPath = shell.resolve(fs.combine("User/Cloud",sFile))
    if not fs.exists(sPath) or not string.find(sPath,"User/Cloud") then
        print("Path not found")
        print("Note: provide a relative path to a file or folder starting from cloud")
        return
    end

    local sName = string.gsub(tArgs[3]," ","_")

    local list = ""
    if listing then
        list = "&listing="..textutils.urlEncode(listing)
    end
    write("Connecting to LevelStore... ")
    local response = http.post(
        "https://os.leveloper.cc/sProject.php",
        "path="..textutils.urlEncode(tArgs[2])..
        "&title="..textutils.urlEncode(sName)..
        "&timestamp="..textutils.urlEncode(tostring(os.epoch("utc")))..
        "&direct="..textutils.urlEncode("false")..
        list,
        {
        	Cookie = lOS.userID
        }
    )

    if response then
        print("Success.")

        local sResponse = response.readAll()
        response.close()

        print("Uploaded as " .. sResponse)
        print("Run \"lStore get " .. sName .. "\" or \"lStore get " .. sResponse .. "\" to download anywhere")

    else
        printError("Failed.")
    end

elseif sCommand == "get" then

    if #tArgs < 3 then
        printUsage()
        return
    end

    -- Determine file to download
    local sCode = tArgs[2]
    local sFile = tArgs[3]
    local sPath = shell.resolve(sFile)
    if fs.exists(sPath) then
        print("Path already exists")
        return
    end

    local tree,folders = get(sCode)
    if not tree then return end
    term.write("Downloading... ")
    local x,y = term.getCursorPos()
    term.write("0%")
    if #tree > 1 or #folders > 0 then
    	fs.makeDir(sPath)
    	for f=1,#folders do
    		fs.makeDir(fs.combine(sPath,folders[f]))
    	end
    	for f=1,#tree do
    		download(sCode,tree[f],fs.combine(sPath,tree[f]))
    		term.setCursorPos(x,y)
    		term.write(math.ceil((f/#tree)*100+0.5).."%")
    	end
    else
    	download(sCode,tree[1],sPath)
    end
    term.setCursorPos(x,y)
    print("100%")
    print("Downloaded as " .. sFile)
elseif sCommand == "run" then
    local sCode = tArgs[2]
    local res
    local tree,folders = get(sCode)
    if not tree then return end
    if #tree > 1 or #folders > 0 then
    	print("This project must be downloaded to run.")
    	return
    else
    	--print(textutils.serialize(tree))
    	res = download(sCode,tree[1],"",true)
    end
    if res then
        local func, err = load(res, sCode, "t", _ENV)
        if not func then
            printError(err)
            return
        end
        local success, msg = pcall(func, select(3, ...))
        if not success then
            printError(msg)
        end
    end
else
    printUsage()
    return
end