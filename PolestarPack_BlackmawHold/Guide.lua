local addon = ...
local P = Polestar
local pack = "blackmaw-hold"
local guideID = pack .. "/horde"
if not P.RegisterPack({addon=addon, id=pack, title="艾萨拉 · 黑喉要塞与坏帽子",
    author="Codex", version="0.1.5", format=11, license="MIT", source="See README.md"}) then return end

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
local scoutGoals={}
local function scout(g)
    scoutGoals[#scoutGoals+1]=g
    return live(g,function() return active(g.quest) or not passedScouts() end)
end
local refreshFire
local function refresh()
    local changed = refreshFire()
    local downstream=passedScouts()
    for _,g in ipairs(scoutGoals) do
        local elective=downstream and active(g.quest) or nil
        if g.optional~=elective then g.optional=elective changed=true end
    end
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

-- Local reminders are independent of the current route step or navigation arrow.
local function atKurllCamp()
    if C.IsOnTaxi() then return false end
    local _,sub=C.GetZoneText()
    local camp=C.GetAreaName(1237)
    if sub and camp then return sub==camp end
    local map,x,y=C.GetPlayerMapPosition()
    return map==A and x and y and math.abs(x-21.9)<=1.4 and math.abs(y-51.1)<=2
end

-- nil means this window gives no evidence about the shark quest.
local offerSource, sharkOffered
local function currentOffer()
    if offerSource and C.GetNpcID("npc")==kurll[1] then return sharkOffered end
end
local function checkSharkPickup()
    if seen(91611) then return false end
    local offered=currentOffer()
    if offered~=nil then return offered end
    return atKurllCamp() and C.GetPlayerInfo().level>=50
        and (C.IsQuestCompleted(91610) or C.IsQuestCompleted(91609))
end

row("瓦罗莫克出发 · 可选治疗帽与根帽",
    sideTake(92346,jediga,"想采根帽就先接，稍后带信去雷霆崖。"),
    sideTake(91488,kurll,"想拿坏帽子就接毛皮任务，再做当季渔汛。交完冬鱿鱼后，再与库尔对话接《致命捕捞》。若看不到渔汛，先学初级钓鱼。冬季可在拍卖行提前买齐 10 条「新鲜的冬鱿鱼」。"),
    info("已有雷霆崖航点可趁第一次回营交皮时飞雷霆崖，交信、接根帽，顺访天望高地，再返回艾萨拉。也可留到打完反攻再走。"))
detour("field-start","瓦罗莫克周围 · 库尔的毛皮",
    sideWork(item(91488,238463,"苔蹄毛皮",5,1,{8759,"苔蹄快步者",A,21.5,54.4},"营地东南找苔蹄鹿，共 5 张。")))
detour("field-start","回库尔处 · 接他今天提供的渔汛",sideGive(91488,kurll,
    "交皮后同库尔对话，自己接实际出现的冬季或夏季渔汛。做冬线可买鱼。蜂蜜另有奖励。"))
local winterSquid=item(91610,13755,"新鲜的冬鱿鱼",10,1,nil,
    "在拍卖行搜索「新鲜的冬鱿鱼」，只买缺的数量，凑齐 10 条交给库尔。也可以在艾萨拉海岸钓。")
if GetLocale()=="zhCN" then winterSquid.text="收集新鲜的冬鱿鱼（拍卖行可买）" end
detour("field-start","库尔的渔汛 · 按任务日志备鱼",
    sideWork(winterSquid),
    sideWork(goal("complete",91609,nil,"夏季仅在实际接到时出现，按日志收集夏日鲈鱼。")))
local pickup=detour(true,"库尔 · 可接时带上《致命捕捞》",
    sideGive(91610,kurll,"达到 50 级后再次对话，接《致命捕捞》。"),
    sideGive(91609,kurll,"交鱼后查看库尔有无《致命捕捞》。"),
    live(sideTake(91611,kurll,"想拿坏帽子就接。到北部外海组队击杀精英巨型鲨鱼，取鲨鱼排回库尔处领奖。"),checkSharkPickup))
for _,g in ipairs(pickup.goals) do
    if g.t=="turnin" then
        live(g,function() return not seen(86746) or atKurllCamp() end)
    end
end
-- Firewater shares the eastbound scout/banner trip and the return to Ursolan.
-- Only the current action appears. A held later quest is sufficient to resume.
local furze={npc=235909,npcName="弗尔泽",map=A,x=45.3,y=22.3}
local elder={npc=235906,npcName="长者荆刺",map=A,x=41.7,y=19.5}
local pot={object=506307,objName="雷加斯大锅",map=A,x=57.7,y=21.0}
local satyrCamp={npc=6200,npcName="雷加斯萨特",map=A,x=52,y=18.6}
local bramble={object=507746,objName="萨特草丛",map=A,x=58.7,y=23.0}
local mote={object=507731,objName="邪能微粒",map=A,x=61.5,y=25.1}
local beasts={npc=6378,npcName="雷首天鸣者",map=A,x=47.7,y=22.8}
local function work(verb,id,name,n,oi,where,note)
    return {verb=verb,item=id,name=name,count=n,oi=oi,where=where,note=note}
end
local fires={
    {86799,"逼近的腐化",furze,elder,"可选火酒线：找弗尔泽接任务，再往西找长者荆刺。",
        "向长者荆刺询问弗尔泽的病情，交完接《意想不到的来源》。"},
    {86804,"意想不到的来源",elder,pot,"在长者荆刺处接任务，去雷加斯营地时顺道点大锅。",
        "点雷加斯大锅（57.7，21.0）交任务，原地接《劳神费力》，之后再打萨特取配方。"},
    {86925,"劳神费力",pot,pot,"先点大锅接《劳神费力》，再顺路打营地里的雷加斯萨特。",
        "把火酒配方带回同一口大锅，然后接下一环。",
        work("collect",235645,"雷加斯火酒配方",1,1,satyrCamp,"击杀营地中的雷加斯萨特取配方。若正在护送，先跟紧囚犯。")},
    {86926,"邪火燃烧，大锅翻腾",pot,pot,"在大锅接配料任务，附近收集 5 份萨特草、1 个邪能微粒。",
        "把两种配料交回雷加斯大锅，就地接《运送火酒》。",
        work("collect",235470,"萨特草",5,1,bramble,"采营地里的萨特草丛，例如大锅东南（58.7，23.0）。"),
        work("collect",235471,"邪能微粒",1,2,mote,"去东南（61.5，25.1）与邪能微粒互动。")},
    {86927,"运送火酒",pot,elder,"从大锅接取火酒；下次回乌索兰复命时，一并带给长者荆刺。",
        "把雷加斯火酒交给长者荆刺，接《转化的酊剂》。"},
    {86812,"转化的酊剂",elder,elder,"向长者荆刺取酊剂，出村向东找受腐化的野兽。",
        "三次试药完成后回长者荆刺处，接《潜在的万灵药》。",
        work("use",235509,"萨特草酊剂",3,1,beasts,"在乌索兰东边找带绿色毒雾的苔蹄快步者或雷首天鸣者。打到约三成生命时使用酊剂，共成功 3 次。")},
    {86813,"潜在的万灵药",elder,elder,"拿到万灵药后，前往弗尔泽（45.3，22.3）。",
        "给药后回长者荆刺（41.7，19.5）交任务并选奖励，火酒线完成。",
        work("use",235510,"荆刺的万灵药",1,1,furze,"对弗尔泽使用荆刺的万灵药，再回长者荆刺处领奖。")},
}
local fireStep=row("顺路 · 乌索兰与雷加斯大锅")
fireStep.along=true
local fireIndex=#steps
local function fireGoal(stage,verb,where,note)
    local g={t=verb,quest=stage[1],title=stage[2],note=note,optional=true,only=hidden}
    for k,v in pairs(where) do g[k]=v end
    fireStep.goals[#fireStep.goals+1]=g
    return g
end
for i,stage in ipairs(fires) do
    stage.take=fireGoal(stage,"accept",stage[3],stage[5])
    stage.take.minLevel,stage.take.qlvl=47,53
    if i>1 then stage.take.preAll={fires[i-1][1]} end
    stage.work={}
    for n=7,#stage do
        local w=stage[n]
        local g=fireGoal(stage,w.verb,w.where,w.note)
        g.item,g.itemName,g.count,g.oi=w.item,w.name,w.count,w.oi
        stage.work[#stage.work+1]=g
    end
    stage.give=fireGoal(stage,"turnin",stage[4],stage[6])
end

local function fireStage()
    for i=#fires,1,-1 do
        local stage=fires[i]
        if C.IsQuestCompleted(stage[1]) then return fires[i+1],false end
        if C.IsOnQuest(stage[1]) then return stage,true end
    end
    return fires[1],false
end
local function near(x,y,where,r)
    return (x-where.x)^2+(y-where.y)^2 <= r*r
end
local function fireArea()
    if C.IsOnTaxi() or C.GetInstanceMapID()==2974 then return end
    local map,x,y=C.GetPlayerMapPosition()
    if map~=A or not x or not y or x<38 or x>69 or y<11 or y>31 then return end
    local visit
    if near(x,y,elder,2) then visit=elder
    elseif near(x,y,furze,2) then visit=furze
    elseif near(x,y,pot,2.5) then visit=pot end
    return visit or "road"
end
local fireStarterSource
local fireMessage,fireKey,fireAnnounced
refreshFire=function()
    local current=P.Engine and P.Engine.GetGuide()
    local place=current and current.id==guideID and fireArea()
    local stage,held
    if place then stage,held=fireStage() end
    local desired={}
    local message,key
    if place and stage then
        local q=stage[1]
        if held then
            if #stage.work==0 or ready(q) then
                desired[stage.give]=true
            else
                local obj=C.GetQuestObjectives(q)
                for _,g in ipairs(stage.work) do
                    local o=obj and obj[g.oi]
                    if not (o and o.finished) then desired[g]=true end
                end
            end
        elseif place==stage[3] and C.GetPlayerInfo().level>=47 then
            if stage~=fires[1] or (C.GetFactionStanding(576) or 0)>=4
                or (fireStarterSource and C.GetNpcID("npc")==furze.npc) then
                desired[stage.take]=true
            end
        end
    end
    local changed=false
    local sk=P.CharState().skipped
    local marks=sk and sk[guideID]
    for i,g in ipairs(fireStep.goals) do
        local show=desired[g] and not (marks and (marks[fireIndex] or marks[fireIndex..":"..i]))
            and not (P.Engine and P.Engine.IsQuestSkipped and P.Engine.IsQuestSkipped(g.quest))
        local mask=hidden
        if show then
            mask=nil
            if not message and place~="road" then
                message="火酒支线 · "..g.title.."："..g.note
                key=i..":"..(place.npc or place.object)
            end
        end
        if g.only~=mask then g.only=mask changed=true end
    end
    fireMessage,fireKey=message,key
    return changed
end
local function fireNotice()
    if fireKey~=fireAnnounced then
        fireAnnounced=fireKey
        if fireMessage then P.Notice(fireMessage) end
    end
end

row("埃达拉斯废墟 · 接主线与首趟副本任务",
    take(86746,ekkal,"从瓦罗莫克出发：坏帽子找库尔（21.8，52.1），采根帽找杰迪加（22.4，51.5）。向东北经过奥汀克时可接巨熊爪与獠牙。"),
    sideTake(92069,ogtinc,"进本击杀枯颌和不屈者，分别取爪、牙。"),
    sideTake(97327,ekkal,"55 级起看本人能否领取，进本顺手收集 5 个袋子。")).label="field-start"
row("雷加斯营地 · 分别清掉三队萨特",
    kill(86746,6200,"雷加斯萨特",5,1,52,18.6),
    kill(86746,6201,"雷加斯潜行者",5,2,52,20.1),
    kill(86746,6202,"雷加斯唤魔者",5,3,50.7,18.5),
    info("三个营地分别计数，沿路只补任务日志里仍欠的种类。"))
row("埃卡尔 · 回报后往乌索兰",give(86746,ekkal),take(86752,ekkal,nil,86746),
    info("向埃卡尔取得报到任务后往北走。"))
row("木喉要塞声望 · 为会见守门者做好准备",
    live({t="rep",faction=576,factionName="木喉要塞",standing=4,map=F,x=62.8,y=7.7,
        note="若乌索兰熊怪不理你，去费伍德北部死木村杀死木熊怪。北洞口纳菲恩可收每组 5 根羽毛。稍后接到酋长任务再专门打酋长。"},
        function() return not (seen(86791) or seen(86777) or seen(86792) or seen(86796) or passedScouts()) end),
    info("木喉声望已中立即可继续前往乌索兰。"))
row("乌索兰 · 找拉格罗尔与诺克",give(86752,gate),take(86791,gate,"想做火酒线，出乌索兰时找弗尔泽（45.3，22.3）和长者荆刺（41.7，19.5）。已接《意想不到的来源》可直接去东边的大锅。",86752),
    sideTake(92066,nok,"双熊图腾在副本内，木喉中立时顺手问诺克。"))
row("雷加斯要塞外 · 找到失踪的科尔萨",give(86791,korsa),
    scout(take(86777,korsa,nil,86791)),scout(take(86792,korsa,nil,86791)),
    info("在科尔萨处接下护符和削减兵力。若日志有《意想不到的来源》，先点雷加斯大锅（57.7，21.0）接配方任务，再杀萨特。"))
row("雷加斯要塞 · 护符与守军",
    scout(item(86777,235334,"菲达雷德的护符",1,1,{6652,"菲达雷德",A,61.5,24.6})),
    scout(kill(86792,236874,GetLocale()=="zhCN" and "雷加斯地狱使者" or "Legashi Hellraiser",6,1,65.7,21.1)),
    scout(kill(86792,236867,GetLocale()=="zhCN" and "雷加斯窃魂者" or "Legashi Soulstealer",4,2,65.5,16.4)),
    scout(kill(86792,236876,GetLocale()=="zhCN" and "雷加斯黑卫士" or "Legashi Blackguard",2,3,65.6,19.6)),
    info("若囚犯正在移动，先跟紧护送；脱险后按日志补杀。地狱使者在要塞约 65.7，21.1。"))
row("雷加斯要塞 · 囚笼护送",
    scout(take(86796,graal,"先清笼边守军。每个人亲自接好，再护送出要塞。若失败，放弃失败的任务，等囚犯回笼后重接。")),
    scout(goal("complete",86796,graal,"紧跟囚犯，途中保护他打过两次伏击。")),
    info("护送结束后回科尔萨交任务，日志显示失败时回笼边重接。"))
detour("field-report","北海岸 · 已接捕捞的队员打鲨鱼",
    sideWork(item(91611,238507,"巨型鲨鱼排",1,1,{12125,"巨型鲨鱼",A,64.7,6.9},
        "从要塞往北下海，沿深浅海交界找巡游的精英鲨鱼。坐标是巡游区，建议组队。")))
local report=take(86797,korsa,"先交护符、削减兵力和护送。接到复命后往西去乌索兰。")
report.preAll={86777,86792,86796}
row("回科尔萨处 · 汇合后复命",scout(give(86777,korsa)),scout(give(86792,korsa)),scout(give(86796,korsa)),
    report,
    info("检查护符、击杀和护送是否都已交付，再向科尔萨接复命。")).label="field-report"
row("乌索兰 · 找护门者拉格罗尔复命",give(86797,gate,"离开科尔萨，向西到乌索兰（42.3，20.1）找拉格罗尔交任务。"),take(86798,gate,nil,86797),
    info("在乌索兰交复命后，接《木喉的增援》再去费伍德北口。"))
row("费伍德森林北口 · 独眼高恩",give(86798,gorn),take(87346,gorn,"接好再去死木村。",86798),
    info("独眼高恩在费伍德最北端木喉隧道附近。"))
row("死木村 · 取酋长武器",item(87346,236631,"血喉粉碎者",1,1,{9462,"血喉酋长",F,62.8,7.7}),
    info("击杀酋长后拾取武器，返回北口。"))
row("独眼高恩 · 带战旗返回艾萨拉",give(87346,gorn),take(86814,gorn,nil,87346),
    info("拿到战旗后返回艾萨拉东北的召唤法阵。想续火酒线可顺访雷加斯大锅，反攻后的回程再找乌索兰的长者。"))
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
        function() return working(92065) and C.GetInstanceMapID()~=2974 end),
    info("从艾萨拉北部熊怪石门穿过隧道进本。")).label="portal"
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
        "已接提尔圣物匣（99187）的圣骑士记得摸血鬃。确认双熊图腾齐全后，从双首领房间下行去尾王；每人摸尸取头颅。若捡到邪能污染的肉，找到食肉鞭笞者时可做《喂食时间！》换种荚。"),
    info("击败瓦罗克斯后每人拾取头颅，回乌索兰交任务。"))
row("乌索兰 · 交尾王头颅与顺路任务",give(92065,gate),sideGive(92066,nok),sideGive(92070,unele),
    info("把头颅交给拉格罗尔，持有双熊图腾的队员顺路找诺克。")).label="boss-return"
row("埃达拉斯废墟 · 归还袋子和狩猎战利品",sideGive(97327,ekkal),sideGive(92069,ogtinc))
row("瓦罗莫克 · 返程领取坏帽子",sideGive(91611,kurll,"领取布甲头部「坏帽子」。"))
row("雷霆崖与莫高雷 · 交根帽与仪祭图腾",sideGive(92343,nara),sideGive(97198,muln))

-- Bound earlier stages to the furthest server-confirmed main quest. Do not
-- infer order between the three scouts and do not latch a character's progress.
local stages={{86746},{86752},{86791},{86777,86792,86796},{86797},{86798},{87346},{86814},{92065}}
local rank={}
for i,stage in ipairs(stages) do for _,q in ipairs(stage) do rank[q]=i end end
local function needed(g)
    local stage=rank[g.quest]
    if not (stage==4 and active(g.quest)) then
        for i=stage+1,#stages do
            for _,q in ipairs(stages[i]) do if seen(q) then return false end end
        end
    end
    if g.quest==86797 then
        if g.t=="turnin" then return active(86797) end
        return not seen(86797) and C.IsQuestCompleted(86777)
            and C.IsQuestCompleted(86792) and C.IsQuestCompleted(86796)
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
-- The native shape includes the list of goal verbs and IDs. Appending a
-- note changes its hash even though every saved step/goal index still fits.
-- Recognize only the exact released layout and retain the original positions.
P.OnInit(function()
    local st=P.CharState()
    local oldShape="32-453615649"
    local version=st.shapeVersions and st.shapeVersions[guideID]
    if version~="0.1.2" and version~="0.1.3" then return end
    if not st.shapes or st.shapes[guideID]~=oldShape then return end
    if st.ownShapes and st.ownShapes[guideID] and st.ownShapes[guideID]~=oldShape then return end
    local keys=st.stepKeys and st.stepKeys[guideID]
    local expected={545278727,255003827,3664376301,1851520238,382492679,1248182368,
        1866880060,823137168,1054024200,474013677,807041949,2738627358,2808224246,
        255005767,2888681197,2629137024,3623233239,254032305,2467652044,779304978,
        1598302883,3664378241,2909865066,4154290729,3319083816,480430595,
        3330376977,255035339,429385690,2312474555,3664378241,86302012}
    if type(keys)~="table" or #keys~=#expected then return end
    for i,k in ipairs(expected) do if keys[i]~=k then return end end
    -- Same DJB2 update that Core/Engine.lua applies to each appended ",note:".
    for _,i in ipairs({7,8,9,11,12,13,15,16,17,18,19,24,28,29}) do
        for byte=1,6 do keys[i]=(keys[i]*33+string.byte(",note:",byte)) % 4294967296 end
    end
    st.shapes[guideID]="32-1823708841"
    if st.ownShapes then st.ownShapes[guideID]=st.shapes[guideID] end
end)

-- The new row is optional even for someone who has passed its first stop.
-- Let checkShape shift old pins/skips normally, without passAdded discarding
-- this newly introduced side chain for the rest of that character's route.
P.OnInit(function()
    local st=P.CharState()
    local version=st.shapeVersions and st.shapeVersions[guideID]
    if version~="0.1.2" and version~="0.1.3" and version~="0.1.4" then return end
    local old="32-1823708841"
    if not st.shapes or st.shapes[guideID]~=old then return end
    if st.ownShapes and st.ownShapes[guideID] and st.ownShapes[guideID]~=old then return end
    local keys=st.stepKeys and st.stepKeys[guideID]
    local expected={545278727,255003827,3664376301,1851520238,382492679,1248182368,
        3775130904,184343404,3818841060,474013677,988436793,3397770618,4293891666,
        255005767,2537349257,3947474524,2991327219,962025037,1709893288,779304978,
        1598302883,3664378241,2909865066,2871462085,3319083816,480430595,
        3330376977,3633532903,2003386166,2312474555,3664378241,86302012}
    if type(keys)~="table" or #keys~=#expected then return end
    for i,k in ipairs(expected) do if keys[i]~=k then return end end
    st.ownShapes=st.ownShapes or {}
    st.ownShapes[guideID]="33-54375496"
end)

P.RegisterGuide({id=guideID,pack=pack,title="艾萨拉 · 黑喉要塞与坏帽子（部落）",
    category="Miscellaneous",faction="Horde",minLevel=47,maxLevel=60,zone=A,zoneName="艾萨拉",
    keywords={"火酒","意想不到的来源","黑喉","坏帽子","光复黑喉","Blackmaw","治疗帽"},version=1,
    why="从瓦罗莫克开始，完成光复黑喉并交回尾王头颅；途中可做火酒支线、取坏帽子及首趟副本奖励。",steps=steps})
local function kurllAction()
    if C.IsQuestCompleted(91611) then return end
    if active(91611) then
        if ready(91611) then return 91611,"turnin","把巨型鲨鱼排交给库尔，奖励选「坏帽子」。" end
        return 91611,"collect","已接《致命捕捞》。可留待下次经过北部外海组队打巨型鲨鱼，再把鲨鱼排带回库尔。"
    end
    local offered=currentOffer()
    if offered then return 91611,"accept","库尔正在提供《致命捕捞》，想拿坏帽子就点「接受」。" end
    if C.IsQuestCompleted(91610) or C.IsQuestCompleted(91609) then
        if offered==false then return end
        local level=C.GetPlayerInfo().level
        if level<50 then return 91611,"accept","渔汛已交，50 级再找库尔接《致命捕捞》。","level" end
        return 91611,"accept","渔汛已交，下一步就在这里：再次与库尔对话，接受《致命捕捞》，完成后选「坏帽子」。"
    end
    for _,q in ipairs({91610,91609,91488}) do
        if active(q) then
            if ready(q) then
                return q,"turnin",q==91488 and "毛皮已齐，找库尔交皮，再问他当前的渔汛任务。" or "鱼已齐，回库尔处交鱼，查看《致命捕捞》。"
            end
            if q==91488 then
                return q,"collect",("苔蹄毛皮 %d/5。营地东南的苔蹄鹿掉落，凑齐后找库尔。"):format(math.min(C.GetItemCount(238463),5))
            elseif q==91610 then
                return q,"collect",("新鲜的冬鱿鱼 %d/10。拍卖行可买，也可沿岸钓，凑齐后找库尔。"):format(math.min(C.GetItemCount(13755),10))
            end
            local obj=(C.GetQuestObjectives(q) or {})[1]
            local count=obj and obj.numFulfilled and obj.numRequired and (" %d/%d"):format(obj.numFulfilled,obj.numRequired) or ""
            return q,"complete","夏季渔汛"..count.."，按任务日志备鱼，齐了再找库尔。"
        end
    end
    if C.IsQuestCompleted(91488) and not (P.Engine.IsQuestSkipped(91610) or P.Engine.IsQuestSkipped(91609)) then
        return 91488,"turnin","毛皮已交，找库尔接他当前提供的渔汛任务。看不到时先检查是否学过初级钓鱼。","offer"
    end
end

local function dismissed(q,verb)
    if P.Engine.IsQuestSkipped(q) then return true end
    local skips=P.CharState().skipped
    local marks=skips and skips[guideID]
    if not marks then return false end
    -- Honor an explicit dismissal of this action, including duplicate return rows.
    for s,step in ipairs(steps) do
        for i,g in ipairs(step.goals) do
            if g.quest==q and g.t==verb and (marks[s] or marks[s..":"..i]) then return true end
        end
    end
    return false
end

local announced
local function campReminder()
    local current=P.Engine and P.Engine.GetGuide()
    if not current or current.id~=guideID or not (currentOffer() or atKurllCamp()) then announced=nil return end
    local q,verb,message,variant=kurllAction()
    if not q or dismissed(q,verb) then announced=nil return end
    local key=q..":"..(variant or verb)

    if announced~=key then
        announced=key
        P.Notice("坏帽子 · 瓦罗莫克（21.8，52.1）："..message)
    end
end

local pending=false
local fireTicker
local function fireActive()
    local g=P.Engine and P.Engine.GetGuide()
    return g and g.id==guideID
end
local function fireTick()
    if not fireActive() then return end
    if refreshFire() then P.Engine.RequestUpdate() end
    fireNotice()
end
local function watchFire()
    if fireActive() then
        if not fireTicker and P.NewTicker then fireTicker=P.NewTicker(2,fireTick) end
        fireTick()
    else
        if fireTicker then fireTicker:Cancel() fireTicker=nil end
        fireAnnounced=nil
        refreshFire()
    end
end
local function scheduleReminder()
    if pending then return end
    pending=true
    P.After(0.15,function() pending=false campReminder() if fireActive() then fireNotice() end end)
end

local function update()
    refresh()
    scheduleReminder()
end
local function readOffer(source)
    offerSource,sharkOffered=nil,nil
    fireStarterSource=nil
    if C.GetNpcID("npc")==furze.npc then
        for _,q in ipairs(C.GetOfferedQuests(source) or {}) do
            if q==fires[1][1] then fireStarterSource=source break end
        end
    elseif C.GetNpcID("npc")==kurll[1] then
        local ids=C.GetOfferedQuests(source)
        if ids then
            offerSource=source
            if source~="detail" then sharkOffered=false end
            for _,q in ipairs(ids) do if q==91611 then sharkOffered=true break end end
        end
    end
    update()
end
local function closeOffer(source)
    if fireStarterSource and (not source or fireStarterSource==source) then
        fireStarterSource=nil
        update()
    end
    if offerSource and (not source or offerSource==source) then
        offerSource,sharkOffered=nil,nil
        update()
    end
end
-- The list from before the fish hand-in no longer describes Kurll's offers.
P.RegisterEvent("QUEST_TURNED_IN",function(_,q)
    if q==91610 or q==91609 then offerSource,sharkOffered=nil,nil end
    update()
end)
P.RegisterEvent("GOSSIP_SHOW",function() readOffer("gossip") end)
P.RegisterEvent("QUEST_GREETING",function() readOffer("greeting") end)
P.RegisterEvent("QUEST_DETAIL",function() readOffer("detail") end)
P.RegisterEvent("GOSSIP_CLOSED",function() closeOffer("gossip") end)
P.RegisterEvent("QUEST_FINISHED",function() closeOffer() end)
P.RegisterEvent("PLAYER_LEAVING_WORLD",function() closeOffer() end)
P.OnLogin(function() update() watchFire() end)
P.On("GUIDE_CHANGED",function() scheduleReminder() watchFire() end)
P.On("PLAYER_UNSKIPPED_QUEST",update)
P.On("PLAYER_SKIPPED_QUEST",update)
for _,event in ipairs({"ZONE_CHANGED","ZONE_CHANGED_INDOORS","PLAYER_CONTROL_GAINED"}) do
    P.RegisterEvent(event,update)
end
for _,event in ipairs({"PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","QUEST_LOG_UPDATE","QUEST_ACCEPTED",
    "QUEST_REMOVED","BAG_UPDATE_DELAYED","PLAYER_LEVEL_UP"}) do P.RegisterEvent(event,update) end
