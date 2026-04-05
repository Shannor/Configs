# AI Workflows
_As of 2026/03/23_

This document is about the different workflows I have tried and think are pretty decent. 
It isn't the **best** but, a way to document my ideas around what I ended up liking and why. 

## [PI](https://pi.dev/)

---
I've stopped using Claude Code or Gemini CLI to use PI instead for now. 
I was a big fan of [ OpenCode ](https://opencode.ai/) at one point, If I ever get tired of PI I'll probably go back to OpenCode.

I currently, don't run that many plugins with Pi tbh. I dont' want to recreate all the tools that already exist out there.
I mostly wanted the stripped down version so that I could understand better what the models themselves actually 
can do without the harness and how to coach them as needed. 

## [ OpenSpec ](https://openspec.dev/)

---
I'm going to try out OpenSpec as my tool to manage planned work for the agents/models. 
I was using Google Conductor before, but it's not applicable to other models and setup and mostly works with Gemini.
Though, Claude can figure it out pretty easily too. 

## Models
_As of 2026/04/03_

- Claude Opus 4.6 (Api Key)
  - Used only for planning, architecture and creating tickets.
- Gemini 3 or 3.1 (Api Key) 
  - Used only for planning, architecture and creating tickets.
- Qwen3 Coder 30B (local)
  - Used for implementation
- GLM 4.7 Flash (local)
  - Used for implementation or planning and architecture

### Plugins

---- 

- npm:pi-prompt-template-model
- npm:pi-subagents
- Custom Extension for [ LM Studio ](extensions/lmStudio.ts)

----

> Why not "pi-teams", I think currently teams starts to put you in the "Vibe Coder" category and you start to lose
> your skills and understanding of the code. Working with one agent at a time and using skills here and there seems to be 
> the better flow for _me_.

Skills
- Make PR

Sub Agents
- TODO

----

## Tips

## LMStudio + Pi

Pi doesn't natively support LMStudio today, but it can be added of course.
I took the lazy way out and told Opus to make the integration for me. I'll also be adding it to the repo though in 
the future.

1. Start LM Studio and load a model (or run lms server start for headless)
2. Launch pi — models are auto-discovered on startup
3. Use /model to select an LM Studio model
4. If you load a new model later, run /lmstudio-refresh
