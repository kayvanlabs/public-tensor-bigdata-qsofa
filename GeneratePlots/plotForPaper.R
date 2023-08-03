source('createBarCharts.R')

library(ggplot2)
library(patchwork)

col_setting <- geom_col(color = "black", position = position_dodge())
ylim_setting <- ylim(0, 1)
xlab_setting <- xlab("CP Decomposition Rank")
line_setting <- geom_vline(aes(xintercept = 4.5), linetype = "dashed")
color_setting <- scale_fill_manual(values=c('gray81','gray61','gray51'))



df_allModels_ecg_6 <- data.frame(Rank = rank_order, 
                               F1 = c(rf_ecg_6_f1_mean, svm_ecg_6_f1_mean, lucck_ecg_6_f1_mean),
                               AUROC = c(rf_ecg_6_auc_mean, svm_ecg_6_auc_mean, lucck_ecg_6_auc_mean), 
                               F1_sd = c(rf_ecg_6_f1_std, svm_ecg_6_f1_std, lucck_ecg_6_f1_std), 
                               AUROC_sd = c(rf_ecg_6_auc_std, svm_ecg_6_auc_std, lucck_ecg_6_auc_std),
                               Model = factor(c(rep("RF", 5), rep("SVM", 5), rep("LUCCK", 5))))

df_allModels_ecg_12 <- data.frame(Rank = rank_order, 
                                  F1 = c(rf_ecg_12_f1_mean, svm_ecg_12_f1_mean, lucck_ecg_12_f1_mean),
                                  AUROC = c(rf_ecg_12_auc_mean, svm_ecg_12_auc_mean, lucck_ecg_12_auc_mean), 
                                  F1_sd = c(rf_ecg_12_f1_std, svm_ecg_12_f1_std, lucck_ecg_12_f1_std), 
                                  AUROC_sd = c(rf_ecg_12_auc_std, svm_ecg_12_auc_std, lucck_ecg_12_auc_std),
                                  Model = factor(c(rep("RF", 5), rep("SVM", 5), rep("LUCCK", 5))))

df_allModels_abp_6 <- data.frame(Rank = rank_order, 
                                 F1 = c(rf_abp_6_f1_mean, svm_abp_6_f1_mean, lucck_abp_6_f1_mean),
                                 AUROC = c(rf_abp_6_auc_mean, svm_abp_6_auc_mean, lucck_abp_6_auc_mean), 
                                 F1_sd = c(rf_abp_6_f1_std, svm_abp_6_f1_std, lucck_abp_6_f1_std), 
                                 AUROC_sd = c(rf_abp_6_auc_std, svm_abp_6_auc_std, lucck_abp_6_auc_std),
                                 Model = factor(c(rep("RF", 5), rep("SVM", 5), rep("LUCCK", 5))))

df_allModels_abp_12 <- data.frame(Rank = rank_order, 
                                 F1 = c(rf_abp_12_f1_mean, svm_abp_12_f1_mean, lucck_abp_12_f1_mean),
                                 AUROC = c(rf_abp_12_auc_mean, svm_abp_12_auc_mean, lucck_abp_12_auc_mean), 
                                 F1_sd = c(rf_abp_12_f1_std, svm_abp_12_f1_std, lucck_abp_12_f1_std), 
                                 AUROC_sd = c(rf_abp_12_auc_std, svm_abp_12_auc_std, lucck_abp_12_auc_std),
                                 Model = factor(c(rep("RF", 5), rep("SVM", 5), rep("LUCCK", 5))))

df_allModels_both_6 <- data.frame(Rank = rank_order, 
                                 F1 = c(rf_ecg_abp_6_f1_mean, svm_ecg_abp_6_f1_mean, lucck_ecg_abp_6_f1_mean),
                                 AUROC = c(rf_ecg_abp_6_auc_mean, svm_ecg_abp_6_auc_mean, lucck_ecg_abp_6_auc_mean), 
                                 F1_sd = c(rf_ecg_abp_6_f1_std, svm_ecg_abp_6_f1_std, lucck_ecg_abp_6_f1_std), 
                                 AUROC_sd = c(rf_ecg_abp_6_auc_std, svm_ecg_abp_6_auc_std, lucck_ecg_abp_6_auc_std),
                                 Model = factor(c(rep("RF", 5), rep("SVM", 5), rep("LUCCK", 5))))

df_allModels_both_12 <- data.frame(Rank = rank_order, 
                                  F1 = c(rf_ecg_abp_12_f1_mean, svm_ecg_abp_12_f1_mean, lucck_ecg_abp_12_f1_mean),
                                  AUROC = c(rf_ecg_abp_12_auc_mean, svm_ecg_abp_12_auc_mean, lucck_ecg_abp_12_auc_mean), 
                                  F1_sd = c(rf_ecg_abp_12_f1_std, svm_ecg_abp_12_f1_std, lucck_ecg_abp_12_f1_std), 
                                  AUROC_sd = c(rf_ecg_abp_12_auc_std, svm_ecg_abp_12_auc_std, lucck_ecg_abp_12_auc_std),
                                  Model = factor(c(rep("RF", 5), rep("SVM", 5), rep("LUCCK", 5))))

df_allModels_both_ehr_6 <- data.frame(Rank = rank_order, 
                                  F1 = c(rf_ehr_ecg_abp_6_f1_mean, svm_ehr_ecg_abp_6_f1_mean, lucck_ehr_ecg_abp_6_f1_mean),
                                  AUROC = c(rf_ehr_ecg_abp_6_auc_mean, svm_ehr_ecg_abp_6_auc_mean, lucck_ehr_ecg_abp_6_auc_mean), 
                                  F1_sd = c(rf_ehr_ecg_abp_6_f1_std, svm_ehr_ecg_abp_6_f1_std, lucck_ehr_ecg_abp_6_f1_std), 
                                  AUROC_sd = c(rf_ehr_ecg_abp_6_auc_std, svm_ehr_ecg_abp_6_auc_std, lucck_ehr_ecg_abp_6_auc_std),
                                  Model = factor(c(rep("RF", 5), rep("SVM", 5), rep("LUCCK", 5))))

df_allModels_both_ehr_12 <- data.frame(Rank = rank_order, 
                                   F1 = c(rf_ehr_ecg_abp_12_f1_mean, svm_ehr_ecg_abp_12_f1_mean, lucck_ehr_ecg_abp_12_f1_mean),
                                   AUROC = c(rf_ehr_ecg_abp_12_auc_mean, svm_ehr_ecg_abp_12_auc_mean, lucck_ehr_ecg_abp_12_auc_mean), 
                                   F1_sd = c(rf_ehr_ecg_abp_12_f1_std, svm_ehr_ecg_abp_12_f1_std, lucck_ehr_ecg_abp_12_f1_std), 
                                   AUROC_sd = c(rf_ehr_ecg_abp_12_auc_std, svm_ehr_ecg_abp_12_auc_std, lucck_ehr_ecg_abp_12_auc_std),
                                   Model = factor(c(rep("RF", 5), rep("SVM", 5), rep("LUCCK", 5))))

## ECG only ##
f1_ecg_6 <- ggplot(data = df_allModels_ecg_6, aes(x = Rank, y = F1, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = F1 - F1_sd, ymax = F1 + F1_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("F1 Score", subtitle = "Models Trained on ECG Features (6 hours)") +
    ylab("F1 Score") + theme(legend.position="none")

auc_ecg_6 <- ggplot(data = df_allModels_ecg_6, aes(x = Rank, y = AUROC, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = AUROC - AUROC_sd, ymax = AUROC + AUROC_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("Area Under ROC Curve (AUROC)", subtitle = "Models Trained on ECG Features (6 hours)") +
    ylab("AUROC")

f1_ecg_12 <- ggplot(data = df_allModels_ecg_12, aes(x = Rank, y = F1, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + color_setting + line_setting +
    geom_errorbar(aes(ymin = F1 - F1_sd, ymax = F1 + F1_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("F1 Score", subtitle = "Models Trained on ECG Features (12 hours)") +
    ylab("F1 Score") + theme(legend.position="none")

auc_ecg_12 <- ggplot(data = df_allModels_ecg_12, aes(x = Rank, y = AUROC, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + color_setting + line_setting +
    geom_errorbar(aes(ymin = AUROC - AUROC_sd, ymax = AUROC + AUROC_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("Area Under ROC Curve (AUROC)", subtitle = "Models Trained on ECG Features (12 hours)") +
    ylab("AUROC")

## ABP Only ##

f1_abp_6 <- ggplot(data = df_allModels_abp_6, aes(x = Rank, y = F1, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = F1 - F1_sd, ymax = F1 + F1_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("F1 Score", subtitle = "Models Trained on Art line Features (6 hours)") +
    ylab("F1 Score") + theme(legend.position="none")

f1_abp_12 <- ggplot(data = df_allModels_abp_12, aes(x = Rank, y = F1, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = F1 - F1_sd, ymax = F1 + F1_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("F1 Score", subtitle = "Models Trained on Art line Features (12 hours)") +
    ylab("F1 Score") + theme(legend.position="none")

auc_abp_6 <- ggplot(data = df_allModels_abp_6, aes(x = Rank, y = AUROC, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = AUROC - AUROC_sd, ymax = AUROC + AUROC_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("Area Under ROC Curve (AUROC)", subtitle = "Models Trained on Art line Features (6 hours)") +
    ylab("AUROC")

auc_abp_12 <- ggplot(data = df_allModels_abp_12, aes(x = Rank, y = AUROC, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = AUROC - AUROC_sd, ymax = AUROC + AUROC_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("Area Under ROC Curve (AUROC)", subtitle = "Models Trained on Art line Features (12 hours)") +
    ylab("AUROC")

## ECG + ABP ##

f1_both_6 <- ggplot(data = df_allModels_both_6, aes(x = Rank, y = F1, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = F1 - F1_sd, ymax = F1 + F1_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("F1 Score", subtitle = "Models Trained on ECG and Art line Features (6 hours)") +
    ylab("F1 Score") + theme(legend.position="none")

f1_both_12 <- ggplot(data = df_allModels_both_12, aes(x = Rank, y = F1, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = F1 - F1_sd, ymax = F1 + F1_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("F1 Score", subtitle = "Models Trained on ECG and Art line Features (12 hours)") +
    ylab("F1 Score") + theme(legend.position="none")

auc_both_6 <- ggplot(data = df_allModels_both_6, aes(x = Rank, y = AUROC, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = AUROC - AUROC_sd, ymax = AUROC + AUROC_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("Area Under ROC Curve (AUROC)", subtitle = "Models Trained on ECG and Art line Features (6 hours)") +
    ylab("AUROC")

auc_both_12 <- ggplot(data = df_allModels_both_12, aes(x = Rank, y = AUROC, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = AUROC - AUROC_sd, ymax = AUROC + AUROC_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("Area Under ROC Curve (AUROC)", subtitle = "Models Trained on ECG and Art line Features (12 hours)") +
    ylab("AUROC")

## ECG + ABP + EHR ##

f1_all_6 <- ggplot(data = df_allModels_both_ehr_6, aes(x = Rank, y = F1, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = F1 - F1_sd, ymax = F1 + F1_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("F1 Score", subtitle = "Models Trained on ECG, Art line, and EHR Features (6 hours)") +
    ylab("F1 Score") + theme(legend.position="none")

f1_all_12 <- ggplot(data = df_allModels_both_ehr_12, aes(x = Rank, y = F1, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = F1 - F1_sd, ymax = F1 + F1_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("F1 Score", subtitle = "Models Trained on ECG, Art line, and EHR Features (12 hours)") +
    ylab("F1 Score") + theme(legend.position="none")

auc_all_6 <- ggplot(data = df_allModels_both_ehr_6, aes(x = Rank, y = AUROC, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = AUROC - AUROC_sd, ymax = AUROC + AUROC_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("Area Under ROC Curve (AUROC)", subtitle = "Models Trained on ECG, Art line, and EHR Features (6 hours)") +
    ylab("AUROC")

auc_all_12 <- ggplot(data = df_allModels_both_ehr_12, aes(x = Rank, y = AUROC, fill = Model)) +
    col_setting + ylim_setting + xlab_setting + theme_bw() + line_setting +
    geom_errorbar(aes(ymin = AUROC - AUROC_sd, ymax = AUROC + AUROC_sd), width = 0.2, position = position_dodge(0.9)) +
    ggtitle("Area Under ROC Curve (AUROC)", subtitle = "Models Trained on ECG, Art line, and EHR Features (12 hours)") +
    ylab("AUROC")

# Save output

ecg_only_6 <- f1_ecg_6 + auc_ecg_6
ggsave('ecg_6.eps', ecg_only_6)

ecg_only_12 <- f1_ecg_12 + auc_ecg_12
ggsave('ecg_12.eps', ecg_only_12)

abp_only_6 <- f1_abp_6 + auc_abp_6
ggsave('abp_6.eps', abp_only_6)

abp_only_12 <- f1_abp_12 + auc_abp_12
ggsave('abp_12.eps', abp_only_12)

both_6 <- f1_both_6 + auc_both_6
ggsave('both_6.eps', both_6)

both12 <- f1_both_12 + auc_both_12
ggsave('both_12.eps', both12)

all_6 <- f1_all_6 + auc_all_6
ggsave('all_6.eps', all_6)

all_12 <- f1_all_12 + auc_all_12
ggsave('all_12.eps', all_12)
