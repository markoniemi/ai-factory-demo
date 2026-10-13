---
id: task-001
status: planned
priority: medium
branch: task/001-ai-blog-post
pr_url: ""
---

# Blog post: "Tekoälyn lyhyt oppimäärä"

Create a blog post titled **"Tekoälyn lyhyt oppimäärä"**. Keep the text short.

## Structure

1. **Buzz-words**: a list of common AI buzz-words.
2. **Short background**: very brief. Cover the Markov chain, with a link to a YouTube video on the history of the Markov chain.
3. **How AI works internally**: link to a YouTube video explaining how AI works internally, to show why we need to minimize tokens.
4. **How to use AI effectively**, in chapters:
   - **Skills**: what a skill is, and why skills need to be short.
   - **Instruction file**: keep it short and refer to other files if necessary.
   - **README files**: where to write them and what they should contain.
   - **MCP**: why use MCP instead of CLI tools, and why to minimize the number of MCPs.
   - **RAG**: what it is and when to use it.
   - **Context**: what it is, and a short description of how to keep it small.
   - **Planning**: why use a plan, an implementation plan, and implementation in phases.
   - **AI coding loop** (or AI coding factory): what it is.

# Implementation Plan

## Open questions (for human to verify)

- **Language:** assume the post is written in Finnish (title is Finnish). Confirm.
- **Location and format:** assume a single Markdown file `blog/tekoalyn-lyhyt-oppimaara.md`, since the repo has no blog framework. Confirm or point to the real blog location.
- **Video links:** choose one YouTube video on the history of the Markov chain and one on how LLMs work internally (tokens, attention). Verify that each link resolves and the content matches before adding it.

## Steps

1. Create branch `feature/001-ai-blog-post` from `main`.
2. Create `blog/tekoalyn-lyhyt-oppimaara.md` with a front-matter title and the sections below in this order. Each section is at most about 5 sentences or bullets.
   1. **Buzz-words**: bullet list (LLM, token, prompt, context window, agent, skill, MCP, RAG, hallucination, fine-tuning, embedding), one short phrase each.
   2. **Tausta**: 2-3 sentences on the Markov chain as the predecessor of next-word prediction, with the history video link.
   3. **Miten tekoäly toimii**: 2-3 sentences with the "how AI works internally" video link. State why each token costs time and money, so we minimize tokens.
   4. **Miten tekoälyä käytetään tehokkaasti**, one `###` chapter each:
      - Skills: what a skill is, and why it must be short (it is loaded into context).
      - Ohjetiedosto (instruction file): keep it short and link to other files for detail.
      - README-tiedostot: where to put them (repo root and per module) and what they contain (purpose, how to run, structure).
      - MCP: why use it instead of CLI tools (typed tools and shared auth), and why to minimize MCPs (tool definitions use context).
      - RAG: retrieval of relevant documents into the prompt, and when to use it (large or changing knowledge, not for small stable docs).
      - Konteksti: what it is, plus tips to keep it small (short instructions, new session per task, summarize, fetch only what is needed).
      - Suunnittelu: why plan first, then an implementation plan, then implement in phases (cheaper to fix a plan than code, and small steps are reviewable).
      - AI-koodausloop / AI-tehdas: the loop draft, plan, implement, review, merge, as in `Tasks/README.md`.
3. Proofread for brevity: remove any section longer than needed. Check Finnish spelling and that all links resolve.
4. Add unit tests: not applicable (content only). Instead verify that the Markdown renders and has no broken links.
5. Commit, push the branch, open a PR, set `pr_url`, and set status to `in_review`.
