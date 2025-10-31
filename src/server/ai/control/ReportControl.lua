--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TalkControl = require(script.Parent.TalkControl)
local ReportType = require(ReplicatedStorage.shared.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local Mission = require(ServerScriptService.server.world.level.mission.Mission)

local RADIO_TOOL = ReplicatedStorage.shared.assets.items.NpcRadioNonFunc
local RADIO_DROPPED_LIFETIME = 10
local MIN_DROP_PUSH = 5
local MAX_DROP_PUSH = 7

local ReportControl = {}
ReportControl.__index = ReportControl

export type ReportControl = typeof(setmetatable({} :: {
	agent: Agent,
	radioTool: typeof(RADIO_TOOL),
	radioEquipped: boolean,
	agentDiedConnection: RBXScriptConnection?,
	reportingOn: {
		reportType: ReportType.ReportType,
		reportDuration: number,
		reportTimer: number
	}?
}, ReportControl))

type Agent = Agent.Agent

function ReportControl.new(agent: Agent): ReportControl
	return setmetatable({
		agent = agent,
		radioTool = RADIO_TOOL:Clone(),
		radioEquipped = false,
		reportingOn = nil :: any,
		agentDiedConnection = nil :: RBXScriptConnection?
	}, ReportControl)
end

function ReportControl.isReporting(self: ReportControl): boolean
	return self.reportingOn ~= nil
end

function ReportControl.isRadioEquipped(self: ReportControl): boolean
	return self:manualRadioEquippedCheck()
end

function ReportControl.reportOn(
	self: ReportControl, reportType: ReportType.ReportType, dialogue: string
): ()
	self:connectDiedConnection()
	local dialogueDur = TalkControl.getStringSpeechDuration(dialogue)
	local reportDur = dialogueDur * (1 + 25 / 100) + 0.5
	self.reportingOn = {
		reportType = reportType,
		reportDuration = reportDur,
		reportTimer = 0
	}
	(self :: any).agent.character.isReporting.Value = true
	self:equipRadio()
end

function ReportControl.reportWithCustomDur(
	self: ReportControl, reportType: ReportType.ReportType, absDur: number
): ()
	self:connectDiedConnection()
	local reportDur = absDur + 0.5
	self.reportingOn = {
		reportType = reportType,
		reportDuration = reportDur,
		reportTimer = 0
	}
	(self :: any).agent.character.isReporting.Value = true
	self:equipRadio()
end

function ReportControl.interruptReport(self: ReportControl): ()
	self.reportingOn = nil
	(self :: any).agent.character.isReporting.Value = false
	self:unequipRadio()
end

function ReportControl.update(self: ReportControl, deltaTime: number): ()
	if self.reportingOn then
		self.reportingOn.reportTimer += deltaTime
		if self.reportingOn.reportTimer >= self.reportingOn.reportDuration then
			Mission.raiseAlertLevel(self.reportingOn.reportType.alertLevelRaiseAmount)
			self.reportingOn = nil
			self.agent.character.isReporting.Value = false
			self:unequipRadio()
		end
	end
end

function ReportControl.equipRadio(self: ReportControl): ()
	if not self:isRadioEquipped() then
		self.radioEquipped = true
		((self :: any).agent.character.Humanoid :: Humanoid):EquipTool(self.radioTool)
	end
end

function ReportControl.unequipRadio(self: ReportControl): ()
	if self:isRadioEquipped() then
		self.radioEquipped = false
		((self :: any).agent.character.Humanoid :: Humanoid):UnequipTools()
	end
end

function ReportControl.dropRadio(self: ReportControl): ()
	local radioTool = self.radioTool
	self.radioTool = nil :: any
	local hanlde = radioTool.Handle
	for _, child in hanlde:GetDescendants() do
		if child:IsA("BasePart") then
			child.CanCollide = true
		end
	end

	hanlde.Parent = workspace
	radioTool:Destroy()
	local dir
	if self.agent.character and self.agent.character:FindFirstChild("HumanoidRootPart") then
		dir = (((self :: any).agent.character :: any).HumanoidRootPart :: BasePart).CFrame.LookVector
	else
		dir = Vector3.new(math.random(), math.random(), math.random()).Unit
	end
	dir *= math.random(MIN_DROP_PUSH, MAX_DROP_PUSH)
	hanlde:ApplyImpulse(dir)

	Debris:AddItem(hanlde, RADIO_DROPPED_LIFETIME)
end

--

function ReportControl.manualRadioEquippedCheck(self: ReportControl): boolean
	return self.radioTool and (self.radioTool.Parent :: any) == self.agent.character
end

function ReportControl.connectDiedConnection(self: ReportControl): ()
	if not self.agentDiedConnection then
		self.agentDiedConnection = (self.agent.character:FindFirstChildOfClass("Humanoid") :: Humanoid).Died:Once(function()
			if self:isRadioEquipped() then
				self:dropRadio()
			else
				self.radioTool:Destroy()
			end
			self:interruptReport()
		end)
	end
end

return ReportControl