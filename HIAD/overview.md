# Proactive Customer Intelligence: Building a Customer Health Monitoring Agent in D365 Customer Service

## Lab Overview

In this lab, participants will learn how to build a proactive customer intelligence system using Dynamics 365 Customer Service, Microsoft Copilot Studio, Power Automate, Dataverse, and Power BI. You will score customer health from live case data, deploy an autonomous agent that flags deteriorating accounts, automate personalised outreach as an owned task, and close the loop with a service recovery path that re-scores the account. The goal is to experience how agent-driven customer success surfaces churn risk before a renewal goes wrong, and leaves evidence behind every action.

Welcome to the Proactive Customer Intelligence Hack in a Day. You are here because you already know how to build a Power Automate flow and a Copilot Studio agent, and you want to know what separates a scoring spreadsheet from a system a customer success organisation would actually run its renewals on.

This session is not a walkthrough of the Dataverse table designer. You will build a proactive customer intelligence system end to end: a deterministic health scoring engine over live Dynamics 365 Customer Service data, an autonomous Copilot Studio agent that detects deterioration and raises governed alerts, AI-generated outreach that lands as an owned task with a deadline, a dashboard your leadership can read, and a service recovery path that closes the loop back into the score.

By the end of the day you will have a system that scores ten accounts identically on every run, alerts on exactly the five that deteriorated, drives a personalised intervention for each, and can prove a Red-tier account recovered to Amber because of work it triggered itself.

## The Problem You Are Solving

Contoso's customer success team manages renewals quarterly, by review meeting, using numbers assembled by hand the night before. The signals that predict churn are all sitting in Dynamics 365 Customer Service already:

- Case volume climbing month over month
- Satisfaction scores drifting down
- Resolution times stretching
- A contract renewal date nobody has looked at

Nobody correlates them. Accounts are discovered to be at risk when a renewal conversation goes badly, which is the one moment intervention is most expensive and least likely to work.

The hard part is not the data. It is agreement. Ask three Customer Success Managers whether Woodgrove Bank is at risk and you get three answers, because each weighs the signals differently and none of them can show their work. A score that changes depending on who calculated it is not intelligence, it is opinion with a number attached.

## What You Will Build

Five deliverables, each consuming the last:

| Deliverable | What It Is |
|---|---|
| **Health Scoring Engine** | A `Customer Health Score` table and a Power Automate flow implementing a four-component algorithm over live case data, producing the same score on every run |
| **Customer Health Monitor** | A Copilot Studio agent that scores the portfolio daily, calls a deterministic detection flow, writes governed alert records, and notifies the owning CSM in Teams |
| **Proactive Outreach Automation** | Severity-driven outreach with AI Builder-generated email, a correctly prioritised Dynamics 365 task, and manager escalation for critical accounts |
| **CSM Intelligence Dashboard** | A five-visual Power BI report embedded in the Customer Service workspace, with a portfolio risk alert to customer success leadership |
| **Service Recovery Path** | Cases from Red-tier accounts routed to a senior queue under a compressed SLA, then re-scored on resolution so recovery is evidenced rather than asserted |

## Key Tools

- **Dynamics 365 Customer Service** — case, satisfaction, account and SLA data, queues and unified routing
- **Microsoft Dataverse** — `Customer Health Score`, `Health Alert` and `Intervention Log` tables
- **Microsoft Power Automate** — scoring, detection, outreach, notification and recovery flows
- **Microsoft Copilot Studio** — the autonomous monitoring agent, its tools and generative orchestration
- **AI Builder prompts** — personalised outreach and grounded leadership summaries
- **Microsoft Teams** — CSM adaptive cards and manager escalation
- **Microsoft Power BI** — the CSM dashboard, embedded into Dynamics 365

## Learning Objectives

By the end of this Hack in a Day, you will be able to:

- Design a scoring model that is deterministic, auditable, and defensible in front of a stakeholder who disagrees with it
- Aggregate live Dynamics 365 case data in Power Automate without the rounding and null-handling defects that cause silent score drift
- Decide correctly what belongs in a flow and what belongs in an agent, and know why putting arithmetic in an agent is a design error
- Build a Copilot Studio agent that orchestrates tools and composes language, while correctness stays with the flows underneath it
- Constrain an AI Builder prompt so generated customer-facing text never leaks internal risk scoring
- Drive severity-based automation that produces exactly one owned, time-bound, auditable intervention per alert
- Model Dataverse data in Power BI across five related tables and embed the result inside a model-driven app
- Compress an SLA for a subset of cases without touching the standard commitment for everyone else
- Prove an outcome with your own environment's data rather than asserting one

## Challenge Overview

| Challenge | Title | Duration |
|---|---|---|
| Prerequisite | Stand Up Contoso's Customer Success Baseline | 30 min |
| 01 | The Scoring Engine — Deterministic Customer Health | 45 min |
| 02 | The Monitoring Agent — Detection, Alerts and Notification | 60 min |
| 03 | Proactive Outreach and Owned Intervention | 45 min |
| 04 | The CSM Dashboard and Portfolio Risk | 30 min |
| 05 | Service Recovery and Proving the Loop Closed | 45 min |

**Total hands-on time:** approximately 4 hours 15 minutes, completed at your own pace.

## Fictional Customer Profile

Throughout this hackathon you build for **Contoso Ltd** — a B2B software and services business with the following customer success profile:

- A portfolio of contracted accounts, managed by three Customer Success Managers
- Support delivered through Dynamics 365 Customer Service, with a standard four-hour first response commitment
- Customer health reviewed quarterly, by hand, in a meeting
- Roughly a third of the portfolio currently sits below an acceptable health threshold, and nobody has quantified it
- Target: continuous evidence-based monitoring, automated intervention the moment an account slips, and priority handling for accounts already known to be at risk

Keep this profile in mind. Your scoring weights, your alert thresholds, and your escalation design should all serve the same Contoso portfolio.

## Support Contact

The CloudLabs support team is available 24/7, 365 days a year, via email and live chat.

Learner Support Contacts:

- **Email Support:** labs-support@spektrasystems.com
- **Live Chat Support:** https://cloudlabs.ai/labs-support

Click **Next** from the bottom-right corner to continue.

![](./media/next.png)
