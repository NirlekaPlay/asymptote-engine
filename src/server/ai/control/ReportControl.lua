--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TalkControl = require(script.Parent.TalkControl)
local ReportType = require(ReplicatedStorage.shared.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local Mission = require(ServerScriptService.server.world.level.mission.Mission)

local ReportControl = {}
ReportControl.__index = ReportControl

export type ReportControl = typeof(setmetatable({} :: {
	agent: Agent,
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
		reportingOn = nil :: any,
		agentDiedConnection = nil :: RBXScriptConnection?
	}, ReportControl)
end

function ReportControl.isReporting(self: ReportControl): boolean
	return self.reportingOn ~= nil
end

function ReportControl.reportOn(
	self: ReportControl, reportType: ReportType.ReportType, dialogue: string
): ()
	if not self.agentDiedConnection then
		self.agentDiedConnection = (self.agent.character:FindFirstChildOfClass("Humanoid") :: Humanoid).Died:Once(function()
			self:interruptReport()
		end)
	end
	local dialogueDur = TalkControl.getStringSpeechDuration(dialogue)
	local reportDur = dialogueDur * (1 + 25 / 100)
	self.reportingOn = {
		reportType = reportType,
		reportDuration = reportDur,
		reportTimer = 0
	}
end

function ReportControl.interruptReport(self: ReportControl): ()
	self.reportingOn = nil
end

function ReportControl.update(self: ReportControl, deltaTime: number): ()
	if self.reportingOn then
		self.reportingOn.reportTimer += deltaTime
		if self.reportingOn.reportTimer >= self.reportingOn.reportDuration then
			Mission.raiseAlertLevel(self.reportingOn.reportType.alertLevelRaiseAmount)
			self.reportingOn = nil
		end
	end
end

return ReportControl