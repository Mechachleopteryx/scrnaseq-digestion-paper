
cell_types = config['cell_types']
pseudobulk = config['pseudobulk']

pt_de_results  = expand("data/primary_tumour_temp_de/{cv}/DE_results_{ct}_pseudobulk_{pb}.rds",
                             cv=cellranger_versions,
                             ct=cell_types,
                             pb=pseudobulk)


pt_figs = expand("figs/primary_tumour_temp_de/{fn}_{cv}_pseudobulk_{pb}.png",
                 fn = ['volcano','grid'],
                 cv = cellranger_versions,
                 pb = pseudobulk)


pdx_de_results = expand("data/pdx_temp_de/{cv}/DE_results_pseudobulk_{pb}.rds",
                             cv=cellranger_versions,
                             pb=pseudobulk)

pdx_figs = expand("figs/pdx_temp_de/{fn}_{cv}_pseudobulk_{pb}.rds",
                 fn = ['volcano','grid','pathway'],
                 cv = cellranger_versions,
                 pb = pseudobulk)

final_fig_pdx = {
    'png': 'figs/differential-expression/pdx_digestion_de_fig.png',
    'rds': 'figs/differential-expression/pdx_digestion_de_fig.rds'
    }

all_figs['pdx-differential-expression'] = [final_fig_pdx['png']]

all_figs['primary-tumour-de'] = expand("figs/differential-expression/primary_tumour_temp_de_{cv}_{pb}.png",
                                       cv=cellranger_versions,
                                       pb=pseudobulk)


all_figs['primary-tumour-supp'] = ['figs/differential-expression/pt-var-response_v3_FALSE.png',
        'figs/differential-expression/pt-var-response_v3_FALSE.png']


deliverables['coregene-df'] = ['data/deliverables/coregene_df-FALSE-v3.csv']

rule pdx_de:
    params:
        curr_dir=os.getcwd()
    input:
        sces_qc
    output:
        rds="data/pdx_temp_de/{cv}/DE_results_pseudobulk_{pb}.rds",
        report="reports/pdx_temp_de/pdx_temp_de_{cv}_pseudobulk_{pb}.html"
    shell:
        "Rscript -e \"rmarkdown::render('pipeline/differential-expression/pdx_temp_de.Rmd', \
        output_file='{params.curr_dir}/{output.report}', \
        knit_root_dir='{params.curr_dir}', \
        params=list(cellranger_version='{wildcards.cv}', \
        pseudobulk='{wildcards.pb}',\
        output_rds='{output.rds}'))\" "

rule pdx_umap:
    params:
        curr_dir=os.getcwd()
    input:
        sces=sces_qc
    output:
        fig_rds="figs/pdx_temp_de/umap-pdx-cl.rds",
        umap_csv="figs/pdx_temp_de/umap-pdx-cl.csv"
    shell:
        "Rscript -e \"rmarkdown::render('pipeline/differential-expression/pdx_umap.Rmd', \
        knit_root_dir='{params.curr_dir}', \
        params=list(cellranger_version='v3', \
        fig_rds='{output.fig_rds}',\
        umap_csv='{output.umap_csv}'))\" "    
    

rule pdx_results:
    params:
        curr_dir=os.getcwd()
    input:
        rds="data/pdx_temp_de/{cv}/DE_results_pseudobulk_{pb}.rds"
    output:
        volcano="figs/pdx_temp_de/volcano_{cv}_pseudobulk_{pb}.rds",
        grid="figs/pdx_temp_de/grid_{cv}_pseudobulk_{pb}.rds",
        pathway="figs/pdx_temp_de/pathway_{cv}_pseudobulk_{pb}.rds",
        report="reports/pdx_temp_de/collated_report_{cv}_pseudobulk_{pb}.html",
        stats="data/statistics/coregeneset_{pb}_{cv}.csv",
        coregene_df="data/deliverables/coregene_df-{pb}-{cv}.csv"
    shell:
        "Rscript -e \"rmarkdown::render('pipeline/differential-expression/pdx_results.Rmd', \
        output_file='{params.curr_dir}/{output.report}', \
        knit_root_dir='{params.curr_dir}', \
        params=list(cellranger_version='{wildcards.cv}', \
        input_rds='{input.rds}',\
        coregene_stats='{output.stats}',\
        coregene_csv='{output.coregene_df}',\
        volcano_plot='{output.volcano}',\
        grid_plot='{output.grid}',\
        pathway_plot='{output.pathway}',\
        pseudobulk='{wildcards.pb}'))\" "

# Note - this is specifically written for CR v3 pseudobulk=FALSE
rule pdx_generate_final_figures:
    params:
        curr_dir=os.getcwd()
    input:
        grid="figs/pdx_temp_de/grid_v3_pseudobulk_FALSE.rds",
        pathway="figs/pdx_temp_de/pathway_v3_pseudobulk_FALSE.rds",
        report="reports/pdx_temp_de/collated_report_v3_pseudobulk_FALSE.html",
        umap_csv="figs/pdx_temp_de/umap-pdx-cl.csv"
    output:
        png=final_fig_pdx['png'],
        rds=final_fig_pdx['rds'],
        report="reports/pdx_temp_de/final_figure.html"
    shell:
        "Rscript -e \"rmarkdown::render('pipeline/differential-expression/pdx_fig.Rmd', \
        output_file='{params.curr_dir}/{output.report}', \
        knit_root_dir='{params.curr_dir}', \
        params=list(umap_csv='{input.umap_csv}', \
        coregeneset_path='{input.grid}', \
        pathway_path='{input.pathway}', \
        fig_png='{output.png}', \
        fig_rds='{output.rds}'))\" "

rule pdx_stats:
    params:
        curr_dir=os.getcwd()
    input:
        rds="data/pdx_temp_de/{cv}/DE_results_pseudobulk_{pb}.rds"
    output:
        "data/statistics/pdx_differential_expression_{pb}_{cv}.csv"
    shell:
        "Rscript pipeline/differential-expression/pdx-differential-expression-stats.R \
        --input_rds {input.rds} \
        --output_csv {output}"


rule primary_tumour_de:
    params:
        curr_dir=os.getcwd()
    input:
        sce="data/primary_tumour_analysis/v5/sce_final_annotated/{cv}.rds"
    output:
        rds="data/primary_tumour_temp_de/{cv}/DE_results_{ct}_pseudobulk_{pb}.rds",
        report="reports/primary_tumour_temp_de/primary_tumour_de_{cv}_{ct}_pseudobulk_{pb}.html"
    shell:
        "Rscript -e \"rmarkdown::render('pipeline/differential-expression/primary_tumour_temp_de.Rmd', \
        output_file='{params.curr_dir}/{output.report}', \
        knit_root_dir='{params.curr_dir}', \
        params=list(cellranger_version='{wildcards.cv}', \
        cell_type='{wildcards.ct}', \
        input_sce='{input.sce}', \
        pseudobulk='{wildcards.pb}',\
        output_rds='{output.rds}'))\" "    

rule primary_tumour_figs:
    params:
        curr_dir=os.getcwd()
    input:
        rds=expand("data/primary_tumour_temp_de/{{cv}}/DE_results_{ct}_pseudobulk_{{pb}}.rds",
                    ct=cell_types),
        pdx_results="data/pdx_temp_de/{cv}/DE_results_pseudobulk_{pb}.rds",
        pt_umap="figs/all-sample-overview/primary-tumour-figs.rds"

    output:
        volcano="figs/primary-tumour-temp-de/volcano_{cv}_pseudobulk_{pb}.png",
        grid="figs/primary-tumour-temp-de/grid_{cv}_pseudobulk_{pb}.png",
        pathway="figs/primary-tumour-temp-de/pathway_{cv}_pseudobulk_{pb}.png",
        report="reports/primary-tumour-temp-de/collated_report_{cv}_pseudobulk_{pb}.html",
        fig="figs/differential-expression/primary_tumour_temp_de_{cv}_{pb}.png",
        sfig_varresp='figs/differential-expression/pt-var-response_{cv}_{pb}.png',
        sfig_props='figs/differential-expression/pt-props_{cv}_{pb}.png'
    shell:
        "Rscript -e \"rmarkdown::render('pipeline/differential-expression/primary_tumour_results.Rmd', \
        output_file='{params.curr_dir}/{output.report}', \
        knit_root_dir='{params.curr_dir}', \
        params=list(cellranger_version='{wildcards.cv}', \
        volcano_plot='{output.volcano}',\
        grid_plot='{output.grid}',\
        sfig_varresp='{output.sfig_varresp}',\
        sfig_props='{output.sfig_props}',\
        pt_umap='{input.pt_umap}',\
        pathway_plot='{output.pathway}',\
        output_fig='{output.fig}',\
        pdx_results='{input.pdx_results}',\
        pseudobulk='{wildcards.pb}'))\" "    
