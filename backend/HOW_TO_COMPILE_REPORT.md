# INSTRUCTIONS: How to Complete Your Unit Testing Report

## Step 1: Take Screenshots

### Screenshot 1: Terminal Output
1. Run the demo: `.\run_demo.ps1`
2. When all tests are running/complete, take a screenshot of the terminal
3. Save as: `terminal_output.png`
4. Place in the `backend` folder

### Screenshot 2: Notepad Report
1. The demo automatically opens the report in Notepad
2. Take a screenshot of the Notepad window showing the full report
3. Save as: `report_notepad.png`
4. Place in the `backend` folder

## Step 2: Update the LaTeX File

Open `Unit_Testing_Report.tex` and find these two sections:

### Around Line 200 (Terminal Screenshot):
Replace:
```latex
\fbox{\rule{0pt}{8cm}\rule{\textwidth}{0pt}}
```
With:
```latex
\includegraphics[width=\textwidth]{terminal_output.png}
```

### Around Line 220 (Report Screenshot):
Replace:
```latex
\fbox{\rule{0pt}{8cm}\rule{\textwidth}{0pt}}
```
With:
```latex
\includegraphics[width=\textwidth]{report_notepad.png}
```

## Step 3: Compile the PDF

### Option A: Using Overleaf (Recommended - No Installation)
1. Go to https://www.overleaf.com
2. Create free account / login
3. Click "New Project" → "Upload Project"
4. Upload `Unit_Testing_Report.tex` and your two PNG images
5. Click "Recompile" 
6. Download the PDF

### Option B: Using MiKTeX (Windows)
1. Install MiKTeX from: https://miktex.org/download
2. Open Command Prompt in backend folder:
   ```
   pdflatex Unit_Testing_Report.tex
   pdflatex Unit_Testing_Report.tex
   ```
   (Run twice to generate table of contents correctly)
3. Open `Unit_Testing_Report.pdf`

### Option C: Using Online LaTeX Compiler
1. Go to https://latexbase.com
2. Copy-paste the contents of `Unit_Testing_Report.tex`
3. Upload the two PNG images
4. Click "Generate PDF"
5. Download the PDF

## Step 4: What You'll Get

A professional 5-6 page PDF report containing:
- ✅ Title page with project summary
- ✅ Table of contents
- ✅ Executive summary
- ✅ Testing methodology
- ✅ YOUR terminal screenshot (all tests passing)
- ✅ YOUR report screenshot (detailed results)
- ✅ Results analysis with tables
- ✅ Code coverage analysis
- ✅ Code examples
- ✅ Conclusions and recommendations

## Quick Summary

```
1. Run: .\run_demo.ps1
2. Screenshot: Terminal (save as terminal_output.png)
3. Screenshot: Notepad (save as report_notepad.png)
4. Edit: Unit_Testing_Report.tex (add image file names)
5. Compile: Use Overleaf or MiKTeX
6. Result: Professional PDF report for your lecturer!
```

## Files You Need
- ✅ Unit_Testing_Report.tex (already created)
- ⏳ terminal_output.png (you need to create this)
- ⏳ report_notepad.png (you need to create this)

## After Compilation
You'll have: `Unit_Testing_Report.pdf` - Ready to submit to your lecturer!
