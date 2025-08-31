--!strict

-- we just gonna create types for anything huh?
-- this shit is to avoid circular dependency bullshit
-- cuz we needed those goddamn types.
-- wtf luau.

local ServerScriptService = game:GetService("ServerScriptService")
local ReportControl = require(ServerScriptService.server.ai.control.ReportControl)

export type ReporterAgent = {
	getReportControl: (self: ReporterAgent) -> ReportControl.ReportControl
}

return nil