# Best practices in structuring research projects

This repository provides a template for good practices in structuring research projects with emphasis on multi-user projects, inspired by GenomeDK – Best practices (https://genome.au.dk/docs/best-practices/). Not your style? Many alternative templates are available at https://www.cookiecutter.io/templates.
Other resources:  
 * Best practice and impact (https://best-practice-and-impact.github.io/qa-of-code-guidance/intro.html)


## Installation
Clone the repository  

	git clone https://github.com/gualpo/best-practices
	cd best-practices

Make setup script executable  

	chmod +x setup_new_project.sh

## Creating a new project

Create project folder

	mkdir NewProject
	cd NewProject

Run the setup script

	../setup_new_project.sh

Evaluate setup

	tree -a


## Directory layout 
### Top-level layout

	.
	├── .admin/			# Project administration
	├── README.md -> .admin/backup/README.md	# Project description
	├── PrimaryData/	# Immutable raw input data
	├── DerivedData/	# Reproducible processed data
	└── WorkSpaces/		# User analysis and development


### .admin (project administration)
Project governance

	.
	├── .admin
	│	└── backup
	│		├── logs
	│		│	└── setup_new_project_log_<timestamp>.out
	│		├── README.md
	│		└── scripts
	│			└── setup
	│				├── setup_new_project.sh
	│				└── setup_utils.sh


### PrimaryData (raw data)
Read-only after deposition.  
Never edited.  
Controlled access.  
Loss is catastrophic.  


	├── PrimaryData
	│	├── backup
	│	│	├── DataSource	# rename to source of data, e.g. assay-batch
	│	│	└── README.md
	│	├── DataSource -> backup/DataSource/
	│	└── README.md -> backup/README.md


### DerivedData (processed samples)
Reproducible from PrimaryData.
Shared across users.
Should not contain ”personal experiments”.

	├── DerivedData
	│	├── backup
	│	│	└── README.md
	│	├── main
	│	├── manifest
	│	├── metadata
	│	├── QC
	│	├── README.md -> backup/README.md
	│	└── reference


### WorkSpaces (each user has a subdirectory)
Can run experiments freely.
Can break things locally without harming others.
No contamination of shared materials.

#### WorkSpaces/\<username\>

	└── WorkSpaces
		└── gualpo
			├── backup
			│	├── docs
			│	├── environment.yml
			│	├── plots		# scripts to plot and resulting plots
			│	├── README.md 	# document user goals
			│	└── scripts
			├── data 			# user-specific data or symlinks to DerivedData
			├── steps			# intermediate data
			├── results			# final data files
			├── workflows		# separate analysis workflows
			│	└── wp1			# name of workflow
			│		├── inputs
			│		├── outputs
			│		├── src
			│		└── workflow.py
			├── environment.yml -> backup/environment.yml
			├── README.md -> backup/README.md
			├── plots -> backup/plots/	
			├── docs -> backup/docs/
			└── scripts -> backup/scripts/



## Naming data files

Structure main data subdirectories from many individuals each with multiple samples.

	DerivedData
	└── <individualID>
		└── <sampleID>_<specimenType>_<batchID>
			├── <sampleID_C>_<specimen>.<properties>.<ext>
			└── workflow
				├── account.txt		# HPC account info
				├── conda.yaml		# environment
				├── README.md
				├── .gwfconf.json	# configuration
				├── ...
				└── workflow.py		# workflow file


Examples

	DerivedData
	├── NGS				# Example for NGS data
	│	└── I01234		# indivudualID
	│		├── S001I01234D_ffpe_B01-001	
	│		│	├── S001I01234D_ffpe.aligned.sorted.markdup.bam
	│		│	├── S001I01234D_ffpe.aligned.sorted.markdup.bam.bai
	│		│	├── S001I01234D_ffpe.multiqc.report.html
	│		│	├── S001I01234D_ffpe.mutect.filtered.vcf.gz
	│		│	├── S001I01234D_ffpe.mutect.filtered.vcf.gz.tbi
	│		│	└── S001I01234D_ffpe.wgs_metrics.txt
	│		└── S002I01234D_buffycoat_B01-002
	│			├── S002I01234D_buffycoat.aligned.sorted.markdup.bam
	│			├── S002I01234D_buffycoat.aligned.sorted.markdup.bam.bai
	│			├── S002I01234D_buffycoat.haplotypecaller.filtered.vcf.gz
	│			├── S002I01234D_buffycoat.haplotypecaller.filtered.vcf.gz.tbi
	│			├── S002I01234D_buffycoat.multiqc.report.html
	│			└── S002I01234D_buffycoat.wgs_metrics.txt
	└── ONT
		└── I01234
			└── S003I01234D_frfr_B02-001
				├── S003I01234D_frfr.aligned.phased.bam
				├── S003I01234D_frfr.aligned.phased.bam.bai
				├── S003I01234D_frfr.clair3.vcf.gz
				├── S003I01234D_frfr.clair3.vcf.gz.tbi
				├── S003I01234D_frfr.cutesv.vcf.gz
				└── S003I01234D_frfr.cutesv.vcf.gz.tbi





