#!/usr/bin/Rscript
library(Biobase)
library(CMScaller)
library(dplyr)
library(survival)
library(optparse)
library(randomForest)
library(tools)
# Rscript wrapper to run CMScaller...
# usage: ./exampleRScript1.r -a thisisa -b hiagain
#        ./exampleRScript1.r --avar thisisa --bvar hiagain

option_list = list(
		    make_option(c("-e", "--expression_matrix_file"), default=NULL, type='character', help="Expression data matrix file"),
		    make_option(c("-l", "--run_lmcms"), default=NULL, type='character', help="run lmcms analysis deafault: No"),
		    make_option(c("-o", "--outdir"), default=getwd(), type='character', help="dir to store output results"),
		    make_option(c("-v", "--verbose"), action="store_true", default=TRUE, help="Should the program print extra stuff out? [default %default]"),
		    make_option(c("-q", "--quiet"), action="store_false", dest="verbose", help="Make the program not be verbose."),
		    make_option(c("-t", "--test"), action="store", default=NULL, help="Run test data provided with CMScaller")
		 );
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

outdir<-opt$outdir
exp_matrix<-opt$expression_matrix_file
file_name<-tools::file_path_sans_ext(exp_matrix)
print(paste("Get file name without extension",file_name,sep=""))

# main point of program is here, do this whether or not "verbose" is set
if (!is.null(exp_matrix) & is.null(opt$test )){
	print("Analysing expresison data")
	print(paste("Plots will be stored in",file_name,".pdf file",sep=""))
        pdf(file=paste(file_name,"_Results_CMScaller.pdf",sep=""))
	df_count <-read.table(exp_matrix ,stringsAsFactors = FALSE, header = TRUE, check.names = FALSE)
        print("Loading expression matrix file:") 
	print(dim(df_count))
	print("Removing non-unique rows")
        unique_rows<-distinct(df_count, entrezid, .keep_all = TRUE)
	print(dim(unique_rows))
	print("creating featureData for expressionset object")
	fdata<-AnnotatedDataFrame(data.frame(unique_rows[unique_rows$biotype=="protein_coding",c(2,3)], row.names = 1, stringsAsFactors=FALSE, check.names = FALSE))
	print("Getting required columns from data frame to be used to generate expression set...")
	subset_columns<-data.frame(unique_rows[unique_rows$biotype=="protein_coding", c(2,7:length(unique_rows))], row.names = 1, stringsAsFactors=FALSE, check.names = FALSE)
	print("rounding off data...")
	subset_columns[,c(2:length(subset_columns))] <- round(subset_columns[,c(2:length(subset_columns))])
	subset=as.matrix(subset_columns)
	print("creating expression set...")
	eset <- new("ExpressionSet", exprs = subset, featureData = fdata)
	print(dim(subset))
	print("Run CMScaller in RNAseq = TRUE mode (CMScaller(data, RNAseq=TRUE, doPlot=TRUE)), saving output to a dataframe")
        res_cms <- CMScaller(emat=subset, RNAseq=TRUE, FDR=0.05, seed=1234, nPerm=10000, doPlot=TRUE)
	print("Rerun CMScaller using the CRIS templates (CMScaller(data, RNAseq=TRUE, templates=CMScaller::templates.CRIS, doPlot=TRUE)), again saving output as a dataframe")
	res_cris <- CMScaller(emat=eset, RNAseq=TRUE, templates=CMScaller::templates.CRIS, doPlot=TRUE)

        # run lmCMS to use random forest method....
        #res_lmCMS <- lmCMScaller(subset, RNAseq = TRUE, posterior=.6)
        #write.table(data.frame("sample"=rownames(res_lmCMS),res_lmCMS),file=paste(file_name,"_lmCMS_classes.tsv", sep=""),sep="\t", quote=F,col.names=T,row.names=F)
        merged_df<-merge(res_cms, res_cris, by=0, all=TRUE)
        colnames(merged_df)<-c('sample','CMS_prediction','CMS1','CMS2','CMS3','CMS4','CMS_pVal','CMS_FDR','CRIS_prediction','CRISA','CRISB','CRISC','CRISD','CRISE','CRIS_pVal','CRIS_FDR')
        write.table(merged_df,file=paste(file_name,"_combined_CMS_classes_and_CRIS_subtypes.tsv",sep=""),sep="\t", quote=F,col.names=T,row.names=F )
	print("Running gsa")
	cam <- CMSgsa(emat=subset, class=res_cms$prediction, RNAseq=TRUE )
	# not valid cris gsea data....??????
	cam <- CMSgsa(emat=subset, class=res_cris$prediction, RNAseq=TRUE )
	print("performing differential expression analysis  .....")
	deg_cms <- subDEG(emat=eset, class=res_cms$prediction, doVoom=TRUE)
	deg_cris <- subDEG(emat=eset, class=res_cris$prediction, doVoom=TRUE)
	subVolcano(deg_cms, geneID="gene")
	subVolcano(deg_cris, geneID="gene")
        dev.off()
}else if (!is.null(exp_matrix) & !is.null(opt$run_lmcms)){
        print("Running liver metastasis samples analysis.....")
        pdf(file=paste(outdir,"/Results_lmCMScaller.pdf",sep=""))
	df_count <-read.table(exp_matrix ,stringsAsFactors = FALSE, header = TRUE, check.names = FALSE)
        print("Loading expression matrix file:") 
	print(dim(df_count))
	print("Removing non-unique rows")
        unique_rows<-distinct(df_count, entrezid, .keep_all = TRUE)
	print(dim(unique_rows))
	print("creating featureData for expressionset object")
	fdata<-AnnotatedDataFrame(data.frame(unique_rows[unique_rows$biotype=="protein_coding",c(2,3)], row.names = 1, stringsAsFactors=FALSE, check.names = FALSE))
	print("Getting required columns from data frame to be used to generate expression set...")
	subset_columns<-data.frame(unique_rows[unique_rows$biotype=="protein_coding", c(2,7:length(unique_rows))], row.names = 1, stringsAsFactors=FALSE, check.names = FALSE)
	subset=as.matrix(subset_columns)
	print("creating expression set...")
	eset <- new("ExpressionSet", exprs = subset, featureData = fdata)
	print(dim(subset))
        data("mcrcOSLOsubset")

        res_lmCMS <- lmCMScaller(subset, posterior=.6)
        cam <- CMSgsa(emat=subset, class=res_lmCMS$prediction,
	                            keepN=!duplicated(subset$`Patient ID`), returnMatrix=TRUE
		                            )
        write.table(data.frame("sample"=rownames(res_lmCMS),res_lmCMS),file=paste(outdir,"/lmCMS_classes.tsv", sep=""),sep="\t", quote=F,col.names=T,row.names=F)
        subPCA(subset, res_lmCMS$prediction)
        dev.off()
     
}else if (!is.null(opt$test)){  
        counts<-exprs(crcTCGAsubset)
        pdf(file=paste(outdir,"/testResults_CMScaller.pdf",sep=""))
        # prediction and gene set analysis
        res_cms <- CMScaller(emat=counts, RNAseq=TRUE, FDR=0.05)
        res_cris <- CMScaller(emat=counts, RNAseq=TRUE, templates=CMScaller::templates.CRIS, doPlot=TRUE)
        merged_df<-merge(res_cms, res_cris, by=0, all=TRUE)
        colnames(merged_df)<-c('sample','CMS_prediction','CMS1','CMS2','CMS3','CMS4','CMS_pVal','CMS_FDR','CRIS_prediction','CRISA','CRISB','CRISC','CRISD','CRISE','CRIS_pVal','CRIS_FDR')
        write.table(merged_df,file=paste(outdir,"/test_combined_CMS_classes_and_CRIS_subtypes.tsv",sep=""),sep="\t", quote=F,col.names=T,row.names=F )
        # gsa analysis
        cam <- CMSgsa(emat=counts, class=res_cms$prediction,RNAseq=TRUE)
        ### limma differential gene expression analysis and visualization
        deg <- subDEG(emat=crcTCGAsubset, class=res_cms$prediction, doVoom=TRUE)
        subVolcano(deg, geneID="symbol")
        dev.off()
# liver metastasis analysis
        pdf(file=paste(outdir,"/testResults_lmCMScaller.pdf",sep=""))
        data("mcrcOSLOsubset")
        res_lmCMS <- lmCMScaller(mcrcOSLOsubset, posterior=.6)
        cam <- CMSgsa(emat=mcrcOSLOsubset, class=res_lmCMS$prediction,
	                            keepN=!duplicated(mcrcOSLOsubset$`Patient ID`), returnMatrix=TRUE
		                            )
        write.table(data.frame("sample"=rownames(res_lmCMS),res_lmCMS),file=paste(outdir,"/test_lmCMS_classes.tsv", sep=""),sep="\t", quote=F,col.names=T,row.names=F)
        subPCA(mcrcOSLOsubset, res_lmCMS$prediction)
        dev.off()
}else {
	            print_help(opt_parser) # print error messages to stderr
            stop("Expression matrix file is required (input expression_matrix_file ).n", call.=FALSE)
}
