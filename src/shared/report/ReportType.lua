--!strict

export type ReportType = {
	reportName: string,
	alertLevelRaiseAmount: number
}

local function register(reportName: string, alertLevelRaiseAmount: number): ReportType
	return {
		reportName = reportName,
		alertLevelRaiseAmount = alertLevelRaiseAmount
	}
end

local REPORT_TYPES = {
	TRESPASSER_SPOTTED = register("trespasser_spotted", 1),
	INTRUDER_SPOTTED = register("intruder_spotted", 4),
	CRIMINAL_SPOTTED = register("criminal_spotted", 4),
	DANGEROUS_ITEM_SPOTTED = register("dangerous_item_spotted", 4),
	NOISE_HEARD = register("noise_heard", 0.5),
	SHOTS_FIRED = register("shots_fired", 4),
	BODY_FOUND = register("body_found", 4),
	ARMED_TRESPASSER = register("armed_trespasser", 4),
	ARMED_PERSON = register("armed_person", 4),
	PERSON_WITH_DANGEROUS_ITEM = register("person_with_dangerous_item", 4)
}

return REPORT_TYPES