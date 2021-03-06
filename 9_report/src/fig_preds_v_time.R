fig_preds_v_time <- function(fig_ind, config_fig_yml, preds_ind, agg_nwis_ind, remake_file, config_file) {
  # read in figure scheme config
  fig_config <- yaml::yaml.load_file(config_fig_yml)

  site_labels <- fig_config$site_abbrev %>%
    bind_rows() %>%
    as.character()
  names(site_labels) <- names(fig_config$site_abbrev)

  # read in the predictions
  preds_df <- readRDS(sc_retrieve(preds_ind, remake_file))

  # read in "truth"
  agg_nwis <- readRDS(sc_retrieve(agg_nwis_ind, remake_file))
  agg_nwis$flux <- left_join(agg_nwis$nitrate_sensor, agg_nwis$flow, by=c('site_no','date'), suffix=c('_conc','_flow')) %>%
    mutate(daily_mean_flux = daily_mean_conc * daily_mean_flow * 60*60*24/1000) %>% # flow in kg/d
    rename(site=site_no)

  # create the plot
  g <- ggplot(mutate(preds_df, LeadTime=as.numeric(Date - ref_date, units='days')), aes(x=Date, y=Flux/1000, color=LeadTime)) +
    geom_point() +
    geom_line(data=dplyr::filter(agg_nwis$flux, date %in% preds_df$Date), size = 1.2,
              aes(x=date, y=daily_mean_flux/1000, linetype = 'Observed'), show.legend = T,
              color=fig_config$model_type$obs) +
    facet_grid(site ~ ., scale='free_y', labeller = labeller(site = site_labels)) +
    scale_color_continuous('Lead Time (d)', low = fig_config$forecast_range$med, high = fig_config$forecast_range$long1) +
    scale_linetype_discrete(name='')+
    xlab('Date') +
    ylab(expression('Nitrate Flux '~(Mg~'N-NO'[3]^'-'~d^{-1}))) +
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          axis.text = element_text(size = 15),
          strip.text = element_text(size = 15),
          axis.title = element_text(size = 15),
          legend.text = element_text(size = 12),
          axis.line = element_line(colour = "black"),
          legend.key = element_blank(),
          strip.background = element_blank())

  # save and post to Drive
  fig_file <- as_data_file(fig_ind)
  ggsave(fig_file, plot=g, width=12, height=6)
  gd_put(remote_ind=fig_ind, local_source=fig_file, config_file=config_file)
}
