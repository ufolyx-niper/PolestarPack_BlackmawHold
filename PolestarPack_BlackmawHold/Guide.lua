local addon = ...
local P = Polestar
local pack = "blackmaw-hold"
local guideID = pack .. "/horde"
if not P.RegisterPack({addon=addon, id=pack, title="艾萨拉 · 黑喉要塞与坏帽子",
    author="Codex", version="0.1.0", format=11, license="MIT", source="See README.md"}) then return end

local A, F = 1447, 1448
local kurll = {3621,"库尔",A,21.8,52.1}
local jediga = {8587,"杰迪加",A,22.4,51.5}
local nara = {5770,"纳拉·蛮鬃",1456,75.7,31.2}
local muln = {259118,"穆恩·大地之怒",1412,33.3,22.5}
local ogtinc = {8405,"奥汀克",A,42.3,42.6}
local ekkal = {235903,"埃卡尔",A,41.9,38.9}
local gate = {236573,"护门者拉格罗尔",A,42.3,20.1}
local nok = {249853,"诺克",A,41.3,20.1}
local korsa = {236770,"科尔萨",A,63,21.4}
local graal = {237007,"Graal",A,65.9,14.4}
local gorn = {11555,"独眼高恩",F,65.2,2.7}
local unele = {249855,"Unele",A,43.4,17.4}

-- title, minimum level, quest level. The client can supply its own localized title.
local quests = {
 [86746]={"雷加斯的威胁",47,53}, [86752]={"向拉格罗尔复命",47,53},
 [86791]={"失踪的黑喉侦察兵",47,53}, [86777]={"菲达雷德",47,53},
 [86792]={"削减兵力",47,54}, [86796]={"萨特，回头见",47,54},
 [86797]={"向拉格罗尔复命",47,53}, [86798]={"木喉的增援",47,55},
 [87346]={"血喉酋长",47,55}, [86814]={"黑喉的反攻",47,55},
 [92065]={"光复黑喉",47,60}, [91488]={"Home on the Range",45,48},
 [91610]={"边境冬日渔汛",45,48}, [91609]={"Summer Frontier Fishery",45,48},
 [91611]={"致命捕捞",50,56}, [92346]={"诺达希尔之底",45,55}, [92343]={"追根溯源",45,55},
 [92069]={"撕裂之爪，刺骨之牙",45,58}, [97327]={"黑喉袋子",55,60},
 [92066]={"双熊",47,55}, [97198]={"黑喉魔法",52,59}, [92070]={"遗失的纪念品",47,55}
}
local steps, watched, ruleFor = {}, {}, {}
local function row(name, ...)
    local s = {title=name, goals={...}}
    steps[#steps+1] = s
    return s
end
-- Show an elective stop beside the active step until its geographic handoff.
local function detour(untilLabel,name,...)
    local s=row(name,...)
    s.along=untilLabel
    for _,g in ipairs(s.goals) do g.optional=true end
    return s
end
local function goal(verb,q,who,note)
    local g = {t=verb,quest=q,title=quests[q][1],note=note}
    if who then g.npc,g.npcName,g.map,g.x,g.y = unpack(who) end
    return g
end
local function take(q,who,note,pre)
    local g = goal("accept",q,who,note)
    g.minLevel,g.qlvl = quests[q][2],quests[q][3]
    if pre then g.preAll = {pre} end
    return g
end
local function give(q,who,note) return goal("turnin",q,who,note) end
local function item(q,id,name,count,index,who,note)
    local g = goal("collect",q,who,note)
    g.item,g.itemName,g.count,g.oi = id,name,count,index
    return g
end
local function kill(q,id,name,count,index,x,y)
    local g = goal("kill",q,{id,name,A,x,y})
    g.target,g.count,g.oi = name,count,index
    return g
end
local C = P.Compat
local function active(q) return C.IsOnQuest(q) and not C.IsQuestCompleted(q) end
local function working(q) return active(q) and not C.IsQuestReadyForTurnIn(q) end
local function ready(q) return active(q) and C.IsQuestReadyForTurnIn(q) end
local function seen(q) return C.IsOnQuest(q) or C.IsQuestCompleted(q) end
local hidden = {factions={"Alliance"}}
local function live(g, show)
    local rule = ruleFor[g]
    if rule then
        local previous = rule.show
        rule.show = function() return previous() and show() end
    else
        rule = {goal=g,show=show}
        watched[#watched+1] = rule
        ruleFor[g] = rule
    end
    g.only = hidden
    return g
end
local function optional(g) g.optional=true return g end
local function sideTake(q,who,note,pre) return optional(take(q,who,note,pre)) end
local function sideGive(q,who,note)
    return live(give(q,who,note),function() return ready(q) end)
end
local function sideWork(g)
    return live(g,function() return working(g.quest) end)
end
local function info(text) return {t="note",text=text} end
-- Later progress can supersede the three field quests even when a player
-- accepted the report before finishing every scout objective.
local function passedScouts()
    for _,q in ipairs({86797,86798,87346,86814,92065}) do
        if seen(q) then return true end
    end
    return false
end
local function scout(g)
    return live(g,function() return not passedScouts() end)
end
local function refresh()
    local changed = false
    for _,w in ipairs(watched) do
        local mask = hidden
        if w.show() then mask=nil end
        if w.goal.only ~= mask then w.goal.only=mask changed=true end
    end
    if changed and P.Engine and P.Engine.GetGuide and P.Engine.RequestUpdate then
        local current=P.Engine.GetGuide()
        if current and current.id==guideID then P.Engine.RequestUpdate() end
    end
end

row("瓦罗莫克出发 · 可选治疗帽与根帽",
    sideTake(92346,jediga,"想采根帽就先接，稍后带信去雷霆崖。"),
    sideTake(91488,kurll,"想拿坏帽子就接。若看不到渔汛，先学初级钓鱼。11 月可提前买 10 条生冬鱿鱼。"),
    info("已有雷霆崖航点可趁第一次回营交皮时飞雷霆崖，交信、接根帽，顺访天望高地，再返回艾萨拉。也可留到打完反攻再走。"))
detour("field-start","瓦罗莫克周围 · 库尔的毛皮",
    sideWork(item(91488,238463,"苔蹄毛皮",5,1,{8759,"苔蹄快步者",A,21.5,54.4},"营地东南找苔蹄鹿，共 5 张。")))
detour("field-start","回库尔处 · 接他今天提供的渔汛",sideGive(91488,kurll,
    "交皮后同库尔对话，自己接实际出现的冬季或夏季渔汛。做冬线可买鱼。蜂蜜另有奖励。"))
detour("field-start","库尔的渔汛 · 按任务日志备鱼",
    sideWork(item(91610,13755,"生冬鱿鱼",10,1,nil,"可提前买齐或在艾萨拉海岸钓齐。")),
    sideWork(goal("complete",91609,nil,"夏季仅在实际接到时出现，按日志收集夏日鲈鱼。")))
detour("field-start","库尔 · 交鱼后带上捕鲨任务",
    sideGive(91610,kurll,"达到 50 级后再次对话，接《致命捕捞》。"),
    sideGive(91609,kurll,"交鱼后查看库尔有无《致命捕捞》。"),
    live(sideTake(91611,kurll,"东北海岸有精英巨型鲨鱼，可与队友同去。"),function()
        return not seen(91611) and (C.IsQuestCompleted(91610) or C.IsQuestCompleted(91609)) end))
row("埃达拉斯废墟 · 接主线与首趟副本任务",
    take(86746,ekkal,"从瓦罗莫克出发：坏帽子找库尔（21.8，52.1），采根帽找杰迪加（22.4，51.5）。向东北经过奥汀克时可接巨熊爪与獠牙。"),
    sideTake(92069,ogtinc,"进本击杀枯颌和不屈者，分别取爪、牙。"),
    sideTake(97327,ekkal,"55 级起看本人能否领取，进本顺手收集 5 个袋子。")).label="field-start"
row("雷加斯营地 · 分别清掉三队萨特",
    kill(86746,6200,"雷加斯萨特",5,1,52,18.6),
    kill(86746,6201,"雷加斯潜行者",5,2,52,20.1),
    kill(86746,6202,"雷加斯唤魔者",5,3,50.7,18.5))
row("埃卡尔 · 回报后往乌索兰",give(86746,ekkal),take(86752,ekkal,nil,86746))
row("木喉要塞声望 · 为会见守门者做好准备",
    live({t="rep",faction=576,factionName="木喉要塞",standing=4,map=F,x=62.8,y=7.7,
        note="若乌索兰熊怪不理你，去费伍德北部死木村杀死木熊怪。北洞口纳菲恩可收每组 5 根羽毛。稍后接到酋长任务再专门打酋长。"},
        function() return not (seen(86791) or seen(86777) or seen(86792) or seen(86796) or passedScouts()) end))
row("乌索兰 · 找拉格罗尔与诺克",give(86752,gate),take(86791,gate,nil,86752),
    sideTake(92066,nok,"双熊图腾在副本内，木喉中立时顺手问诺克。"))
row("雷加斯要塞外 · 找到失踪的科尔萨",give(86791,korsa),
    scout(take(86777,korsa,nil,86791)),scout(take(86792,korsa,nil,86791)))
row("雷加斯要塞 · 护符与守军",
    scout(item(86777,235334,"菲达雷德的护符",1,1,{6652,"菲达雷德",A,61.5,24.6})),
    scout(kill(86792,236874,"Legashi Hellraiser",6,1,65.7,21.1)),
    scout(kill(86792,236867,"Legashi Soulstealer",4,2,65.5,16.4)),
    scout(kill(86792,236876,"Legashi Blackguard",2,3,65.6,19.6)))
row("雷加斯要塞 · 囚笼护送",
    scout(take(86796,graal,"先清笼边守军。每个人亲自接好，再护送出要塞。若失败，放弃失败的任务，等囚犯回笼后重接。")),
    scout(goal("complete",86796,graal,"紧跟囚犯，途中保护他打过两次伏击。")))
detour("field-report","北海岸 · 已接捕捞的队员打鲨鱼",
    sideWork(item(91611,238507,"巨型鲨鱼排",1,1,{12125,"巨型鲨鱼",A,64.7,6.9},
        "从要塞往北下海，沿深浅海交界找巡游的精英鲨鱼。坐标是巡游区，建议组队。")))
row("回科尔萨处 · 汇合后复命",scout(give(86777,korsa)),scout(give(86792,korsa)),scout(give(86796,korsa)),
    take(86797,korsa,"先交已做完的三项。如果科尔萨已给复命可直接接，按你的日志往下走。")).label="field-report"
row("乌索兰 · 去费伍德求援",give(86797,gate),take(86798,gate,nil,86797))
row("费伍德森林北口 · 独眼高恩",give(86798,gorn),take(87346,gorn,"接好再去死木村。",86798))
row("死木村 · 取酋长武器",item(87346,236631,"血喉粉碎者",1,1,{9462,"血喉酋长",F,62.8,7.7}))
row("独眼高恩 · 带战旗返回艾萨拉",give(87346,gorn),take(86814,gorn,nil,87346))
row("雷加斯要塞 · 插旗发起反攻",
    kill(86814,235892,"Prince Halanox",1,1,66.8,19),
    info("站在东北要塞的召唤法阵上使用背包里的木喉战旗，再击败召出的王子。队员各自确认任务变成可交。"))
row("乌索兰 · 进本前亲自接尾王",give(86814,gate),
    take(92065,gate,"尾王任务不可分享。准备根帽或仪祭图腾的队员，从瓦罗莫克飞雷霆崖交信，再去天望高地，取好任务后回入口。",86814),
    sideTake(92066,nok,"之前错过双熊可在这里补接。"))
detour("portal","瓦罗莫克 · 飞行时交鲨鱼排",sideGive(91611,kurll,"三选一，请选择布甲头部「坏帽子」。"))
detour("portal","雷霆崖与天望高地 · 可选的进本准备",
    sideGive(92346,nara,"接下《追根溯源》，本内沿地面采 10 个根帽。"),
    sideTake(92343,nara,"交杰迪加的信后领取，再去莫高雷。",92346),
    sideTake(97198,muln,"52 级起天望高地领取；长老萨满血鬃掉图腾。已在莫高雷时可提前接。"))
row("艾萨拉 · 进入黑喉要塞",
    live({t="enter",area=16554,location="黑喉要塞",map=A,x=34.9,y=23.8,
        note="由北部熊怪石门进洞，沿隧道到传送门。建议 55–60 级组五人队，剩余可选任务可留待下次。"},
        function() return working(92065) and C.GetInstanceMapID()~=2974 end)).label="portal"
local function dungeonSide(g)
    optional(g)
    return live(g,function() return C.GetInstanceMapID()==2974 and working(g.quest) end)
end
local function along(name,...)
    local s=row(name,...)
    s.along="boss-return"
end
along("沿途拾取 · 根帽、袋子与图腾",
    dungeonSide(item(92343,250773,"诺达希尔根帽",10,1,nil,"查看洞内地面，边走边采。")),
    dungeonSide(item(97327,273050,"黑喉袋子",5,1,nil,"沿途搜熊怪尸体。")),
    dungeonSide(item(92066,249694,"乌索克的图腾",1,1,nil,"在黑喉巨兽房间门前，清旁边一组守卫后拾取；跳下尾王洞前拿好。")),
    dungeonSide(item(92066,249693,"乌索尔的图腾",1,2,nil,"在长老萨满血鬃的房间内，首领对面拾取。")))
along("副本首领 · 爪、牙与仪祭图腾",
    dungeonSide(item(92069,249697,"巨熊之爪",1,1,{247195,"枯颌"})),
    dungeonSide(item(92069,249696,"不屈者之牙",1,2,{247198,"不屈者"})),
    dungeonSide(item(97198,276893,"黑喉仪祭图腾",1,1,{247209,"长老萨满血鬃"})))
local necklace=sideTake(92070,nil,"使用掉落的项链接任务，出本交给乌索兰的 Unele。")
necklace.item,necklace.itemName=249698,"羽饰护符项链"
along("背包 · 羽饰护符项链",live(necklace,function() return C.GetItemCount(249698)>0 and not seen(92070) end))
row("黑喉要塞 · 瓦罗克斯·暗蹄",
    item(92065,249692,"瓦罗克斯·暗蹄的头颅",1,1,{247234,"瓦罗克斯·暗蹄"},
        "已接提尔圣物匣（99187）的圣骑士记得摸血鬃。确认双熊图腾齐全后，从双首领房间下行去尾王；每人摸尸取头颅。若捡到邪能污染的肉，找到食肉鞭笞者时可做《喂食时间！》换种荚。"))
row("乌索兰 · 交尾王头颅与顺路任务",give(92065,gate),sideGive(92066,nok),sideGive(92070,unele)).label="boss-return"
row("埃达拉斯废墟 · 归还袋子和狩猎战利品",sideGive(97327,ekkal),sideGive(92069,ogtinc))
row("瓦罗莫克 · 返程领取坏帽子",sideGive(91611,kurll,"领取布甲头部「坏帽子」。"))
row("雷霆崖与莫高雷 · 交根帽与仪祭图腾",sideGive(92343,nara),sideGive(97198,muln))

-- Bound earlier stages to the furthest server-confirmed main quest. Do not
-- infer order between the three scouts and do not latch a character's progress.
local stages={{86746},{86752},{86791},{86777,86792,86796},{86797},{86798},{87346},{86814},{92065}}
local rank={}
for i,stage in ipairs(stages) do for _,q in ipairs(stage) do rank[q]=i end end
local function needed(g)
    for i=rank[g.quest]+1,#stages do
        for _,q in ipairs(stages[i]) do if seen(q) then return false end end
    end
    if g.t=="collect" or g.t=="kill" or g.t=="complete" then return working(g.quest) end
    if g.t=="turnin" then return ready(g.quest) end
    return not C.IsQuestCompleted(g.quest)
end
for _,s in ipairs(steps) do
    for _,g in ipairs(s.goals) do
        if rank[g.quest] then
            local target=g
            live(target,function() return needed(target) end)
        end
    end
end
-- Show the opening waypoint until arrival, a manual skip, or relevant quest progress.
-- Veterans already holding a main quest can resume where they are.
table.insert(steps[1].goals,1,live({t="goto",location="瓦罗莫克",map=A,x=21.8,y=52.1,
    note="先决定是否接库尔的坏帽子线和杰迪加的根帽线。已经在埃卡尔旁、只跑主线时可跳过本步。"},
    function()
        for q in pairs(rank) do if seen(q) then return false end end
        return not (seen(91488) or seen(92346) or seen(91611))
    end))
P.RegisterGuide({id=guideID,pack=pack,title="艾萨拉 · 黑喉要塞与坏帽子（部落）",
    category="Miscellaneous",faction="Horde",minLevel=47,maxLevel=60,zone=A,zoneName="艾萨拉",
    keywords={"黑喉","坏帽子","光复黑喉","Blackmaw","治疗帽"},version=1,
    why="从瓦罗莫克开始，完成光复黑喉并交回尾王头颅；途中可取坏帽子及首趟副本奖励。",steps=steps})
P.OnLogin(refresh)
for _,event in ipairs({"PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","QUEST_LOG_UPDATE","QUEST_ACCEPTED",
    "QUEST_REMOVED","QUEST_TURNED_IN","BAG_UPDATE_DELAYED","PLAYER_LEVEL_UP"}) do P.RegisterEvent(event,refresh) end
