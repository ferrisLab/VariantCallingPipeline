## Bioinformatics Pipeline for Processing Paired-End ddRAD Data

This tutorial provides a step-by-step guide to process paired-end ddRAD data from FASTQ to VCF files using scripts and pipelines developed by Findley Finseth and Thom Nelson.

### Clone repository to your local machine

```bash
git clone https://github.com/ferrisLab/VariantCallingPipeline.git
```

**If you make changes to global variables or anything else that is NOT project specific, please test (make sure they work) and then push those changes to the repository.**

### Prerequisites

1. **Request to Duke University Sequencing Core**
	- Demultiplex libraries by *i7*.

3. **Software and Tools:**

    - Unix-based OS (Linux, MacOS)
    - Stacks
    - Python
    - FastQC
    - MultiQC
    - Picard
    - GATK
    - BWA
    - Samtools
2. **Input Data:**
    
    - Paired-end FASTQ files
    - Barcode sequences
3. **Resource Protocol:**
    
    - Fishman Lab Demultiplexing Protocol: [dx.doi.org/10.17504/protocols.io.bjnbkman](https://dx.doi.org/10.17504/protocols.io.bjnbkman)

:::callout-warning
Note: Pay attention to comments left by other users on the protocol.
:::
---

### Environment and File Preparation (Step 1 - Step 4)

#### Step 1: Initial Preparation
-  Linux/Unix environment: Make sure your are comfortable navigating a Linux/Unix environment. If not, take the time to do so. You will be working in it a lot. 
- Setup your HPC Cypress directory to download/upload the sequence files

An example directory should look like this:
```
path/to/your/directory/
├── input_data/
│ ├── raw_files/
│ │ ├── CMD1_S19_L002_R1_001.fastq.gz
│ │ ├── CMD1_S13_L001_I1_001.fastq.g
│ ├── working_files/
│ │ ├── CMD1_S19_L002_R1_001.fastq.gz
│ │ ├── CMD1_S13_L001_I1_001.fastq.gz
│ │ └── ...
│ └── metadata/
│ ├── ddrad_barcode_seqs.txt
│ ├── barcode_seqs.txt
│ └── ...
├── scripts/
│ ├── demultiplex/
│ │ ├── rmdup_molbarcodes.py
│ │ ├── flip2BeRAD.py
│ │ ├── flipreads_slurm.sh
│ │ ├── process_slurm.sh
│ │ ├── rmdup_slurm.sh
│ │ └── ...
```
There will be multiple `working_files` directories. Each represents a multiplexed/pooled library or a "plate" if you will. 

The `metadata` directory has all the information about your libraries. 
**We will see an complete example directory below**


#### Step 2: File Renaming and Organization

- **Renaming Files:** Skip Step 1 in the Fishman Lab Protocol since Duke performs i7 demultiplexing. Rename your files as follows to match the required format:

```bash
mv CMD1_S19_L002_R1_001.fastq.gz CMD1.1.fastq.gz
mv CMD1_S13_L001_I1_001.fastq.gz CMD1-L001.i7.fastq.gz
```
    
Ensure to make duplicates of the original files before renaming. For example, keep a file in a "RAW" directory.


#### Step 3: Unzipping Files

- **Unzipping Files for Processing:** Unzip only the `rmdup` files before proceeding to Step 3 using the `gunzip` command:
    
```bash
gunzip *.rmdup.*.fastq.gz
```    

#### Step 4: Barcodes Preparation

- **Barcodes in Step 3 and Step 4:** Barcodes should be formatted differently for each step.
    
    - **Step 3:** Use the "barcode_seqs.txt" file from Caroline's "2_demultiplex" folders.
    - **Step 4:** Barcodes should be embedded within the cut site (e.g., `GGGGAAGAATGCA`).
- **Cleaning Up Barcodes:** Remove hidden characters in the barcode file for `flip2BeRAD.py`:

```bash
sed 's/[^A-Za-z0-9_.;]//g' ddrad_barcode_seqs.txt > barcode_seqs.txt
```

---

### Demultiplexing (Step 5 and 6)

#### Step 5: Demultiplexing

- **Demultiplexing:** Demultiplexing to individual samples is completed after Step 4.

#### Step 6: Rmdup and Flipreads

- **Separate Scripts:** Create separate `rmdup` and `flipreads` scripts for each library since these tools are not optimized for running libraries in an array.
- **Execution:** Run `flipreads` scripts one at a time to avoid conflicts due to intermediate/output files having the same name.

---

### Troubleshooting (Step 7)

#### Step 7: Handling Unix Line Breaks

- **File Conversion:** If experiencing issues with executing Unix commands, convert files to Unix line breaks:
```bash
dos2unix filename
```    
- **Troubleshooting Resource:** [Faircloth Lab Protocols](https://protocols.faircloth-lab.org/en/latest/protocols-computer/sequencing/sequencing-fix-incorrect-demultiplexing.html)
    

---

### Explanation of Advanced Topics

#### Process_shortreads vs. Process_radtags

- **Reason for Using Process_shortreads:**
    - The `process_shortreads` tool is used because it accommodates the bestRAD protocol, which allows restriction enzymes on either end. The `process_radtags` tool, even with the `--bestrad` option, is less suited for this specific protocol.

#### Understanding .rem Reads

- **Definition of .rem Reads:**
    
    - `.rem.1.fq` contains single-end reads where the paired-end read was discarded.
    - `.rem.2.fq` contains paired-end reads where the single-end read was discarded.
- **Handling .rem Reads:**
    
    - Proceed without using `.rem` reads; use only `.1` and `.2` reads.

---

### Conclusion

By following these steps, you can successfully process paired-end ddRAD data from FASTQ to VCF files. Always ensure to refer to the provided protocols and tools documentation for detailed information and troubleshooting.

For further questions or support, refer to the provided resources or contact the development team. 
