--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TestService = game:GetService("TestService")
local IntertitlesScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.screens.IntertitlesScreen)
local misssion_dennis_intro = require(TestService.intertitles.misssion_dennis_intro)
local CinematicsDirector = require(ReplicatedStorage.shared.cinematic.CinematicsDirector)

local dir = CinematicsDirector.fromData(misssion_dennis_intro)
dir:runScene("intro", IntertitlesScreen)