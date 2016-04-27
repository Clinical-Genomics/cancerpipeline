#!/bin/bash

# exit on error
set -e

# exit on using unset var
set -u

#############
# FUNCTIONS #
#############

log() {
    NOW=$(date +"%Y%m%d%H%M%S")
    echo "[${NOW}] $@"
}

# make sure to clean up on exit
cleanup() {
    if [[ -n ${CHROM_BAM_DIR} && -e ${CHROM_BAM_DIR} ]]; then
        log "Removing ${CHROM_BAM_DIR}..."
        rm -rf ${CHROM_BAM_DIR}
    fi
}
#trap cleanup ERR EXIT

########
# VARS #
########

IN_NORMAL_BAM=$1
IN_TUMOR_BAM=$2
OUT_VCF_DIR=$3

IN_NORMAL_DIR=$(dirname ${IN_NORMAL_BAM})
IN_TUMOR_DIR=$(dirname ${IN_TUMOR_BAM})

########
# MAIN #
########

# create a place to store the individual bam files
CHROM_NORMAL_BAM_DIR=${IN_NORMAL_DIR}/tmp/
CHROM_TUMOR_BAM_DIR=${IN_TUMOR_DIR}/tmp/
mkdir -p ${CHROM_NORMAL_BAM_DIR}
mkdir -p ${CHROM_TUMOR_BAM_DIR}

# run!
for CHROM in {1..22} X Y MT; do
    log "Extract chromosome ${CHROM}..."
    CHROM_NORMAL_BAM=${CHROM_NORMAL_BAM_DIR}/${CHROM}_NORMAL.bam
    CHROM_TUMOR_BAM=${CHROM_TUMOR_BAM_DIR}/${CHROM}_TUMOR.bam
    # extract
    log "/mnt/hds/proj/bioinfo/components/maintainance/miniconda/envs/cancer/bin/sambamba view -h -t 4 --format bam --show-progress --output-filename=${CHROM_NORMAL_BAM} ${IN_NORMAL_BAM} ${CHROM} &"
    /mnt/hds/proj/bioinfo/components/maintainance/miniconda/envs/cancer/bin/sambamba view -h -t 4 --format bam --show-progress --output-filename=${CHROM_NORMAL_BAM} ${IN_NORMAL_BAM} ${CHROM} &
    log "/mnt/hds/proj/bioinfo/components/maintainance/miniconda/envs/cancer/bin/sambamba view -h -t 4 --format bam --show-progress --output-filename=${CHROM_TUMOR_BAM} ${IN_TUMOR_BAM} ${CHROM}"
    /mnt/hds/proj/bioinfo/components/maintainance/miniconda/envs/cancer/bin/sambamba view -h -t 4 --format bam --show-progress --output-filename=${CHROM_TUMOR_BAM} ${IN_TUMOR_BAM} ${CHROM}

    wait

    OUT_VCF=${OUT_VCF_DIR}/${CHROM}.vcf
    log "Submit chromosome ${CHROM} to SLURM..."
    log "sbatch /mnt/hds/proj/cust000/speedseq/scripts/CCEtumorNormal/mutect2.sh ${CHROM_NORMAL_BAM} ${CHROM_TUMOR_BAM} ${OUT_VCF}"
    sbatch /mnt/hds/proj/cust000/speedseq/scripts/CCEtumorNormal/mutect2.sh ${CHROM_NORMAL_BAM} ${CHROM_TUMOR_BAM} ${OUT_VCF}
done

############
# CLEAN UP #
############


log "Finished"
