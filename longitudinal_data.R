library(lavaan)
library(dplyr)
library(tidyr)
library(ggplot2)

growth_model <- "
					# intercept, slope, quadratic with fixed coefficients
					i =~ 1*y0 + 1*y1 + 1*y2 + 1*y3
					s =~ 0*y0 + 1*y1 + 2*y2 + 3*y3
					q =~ 0*y0 + 1*y1 + 4*y2 + 9*y3
					i ~ 0*1
					s ~ 5*1
					q ~ -1.25*1
					i ~~ 4*i
					s ~~ .1*s
					q ~~ .1*q"

growth_model_to_fit <- "
					# intercept, slope, quadratic with fixed coefficients
					i =~ 1*y0 + 1*y1 + 1*y2 + 1*y3
					s =~ 0*y0 + 1*y1 + 2*y2 + 3*y3
					q =~ 0*y0 + 1*y1 + 4*y2 + 9*y3"
set.seed(3)
growth_data <- lavaan::simulateData(model = growth_model, model.type = 'growth', sample.nobs = 200)

growth_fit <- lavaan::growth(model = growth_model_to_fit, data = growth_data)
summary(growth_fit)

growth_data_l <- gather(mutate(growth_data, ID = 1:n()), key, value, -ID) %>%
  extract(key, into = c('var', 'wave'), regex = '(y)(\\d+)') %>%
  mutate(wave = as.numeric(wave)) %>%
  spread(var, value)

ajitter <- position_jitter(width = .05)
acoord <-  coord_cartesian(ylim = c(-7.5, 12.5))
ggplot(growth_data_l, aes(x = wave, y = y)) +
  geom_point(position = ajitter) + 
  geom_smooth(method = 'glm', formula = y ~ poly(x, 2)) + 
  acoord

ggplot(ald_growth_data_l, aes(x = wave, y = y)) +
  geom_point(position = ajitter, alpha = .5) + 
  geom_line(aes(group = ID), position = ajitter,
            alpha = .5) + 
  acoord

ggplot(ald_growth_data_l, aes(x = wave, y = y)) +
  geom_point(position = ajitter, alpha = .5) + 
  geom_line(aes(group = ID), stat = 'smooth', method = 'glm', formula = y ~ poly(x, 1),
            alpha = .5) + 
  acoord

pred_data <- as_tibble(as.data.frame(lavPredict(growth_fit, type = 'ov', method = 'Bartlett')))
pred_data_l <- gather(mutate(pred_data, ID = 1:n()), key, value, -ID) %>%
  extract(key, into = c('var', 'wave'), regex = '(\\w+)(\\d+)') %>%
  mutate(wave = as.numeric(wave), var = 'y_pred') %>%
  spread(var, value) %>%
  left_join(growth_data_l) %>%
  mutate(wave_jitter = wave + runif(n(), -.25, .25))

ggplot(pred_data_l, aes(x = wave_jitter, y = y)) +
  geom_point(alpha = .5) + 
  geom_line(aes(group = ID, y = y_pred), 
            alpha = .1)

ggplot(pred_data_l, aes(x = wave_jitter, y = y)) +
  geom_point(alpha = 1) + 
  geom_line(aes(group = ID, y = y_pred), size = 1,
            alpha = .25) + 
  geom_segment(aes(xend = wave_jitter, yend = y_pred), alpha = 1) + 
  coord_cartesian(ylim = c(5, 9), xlim = c(.5, 1.5))


growth_model_to_est_3wave <- "
					# intercept and slope with fixed coefficients
					i =~ 1*y0 + 1*y1 + 1*y2
					s =~ 0*y0 + 1*y1 + 2*y2
					q =~ 0*y0 + 1*y1 + 4*y2
					# If I don't set this, the model will have -3 df
					y0 ~~ 0*y0
					y1 ~~ 0*y1
					y2 ~~ 0*y2
					"

growth_fit_3wave <- lavaan::growth(model = growth_model_to_est_3wave, data = select(growth_data, -y3))
summary(growth_fit_3wave)

pred_data_3 <- as_tibble(as.data.frame(lavPredict(growth_fit_3wave, type = 'ov', method = 'Bartlett')))
pred_data_3_l <- gather(mutate(pred_data_3, ID = 1:n()), key, value, -ID) %>%
  extract(key, into = c('var', 'wave'), regex = '(\\w+)(\\d+)') %>%
  mutate(wave = as.numeric(wave), var = 'y_pred') %>%
  spread(var, value) %>%
  left_join(growth_data_l) %>%
  mutate(wave_jitter = wave + runif(n(), -.25, .25))

ggplot(pred_data_3_l, aes(x = wave_jitter, y = y)) +
  geom_point(alpha = .5) + 
  geom_line(aes(group = ID, y = y_pred), 
            alpha = .1)

ggplot(pred_data_3_l, aes(x = wave_jitter, y = y)) +
  geom_point(alpha = 1) + 
  geom_line(aes(group = ID, y = y_pred), size = 1,
            alpha = .25) + 
  geom_segment(aes(xend = wave_jitter, yend = y_pred), alpha = 1) + 
  coord_cartesian(ylim = c(5, 9), xlim = c(.5, 1.5))

npoints <- 10
start <- 0
stop <- 3
lin_weight <- seq(start, stop, length.out = npoints)
ald_growth_model <- paste0("
# intercept and slope with fixed coefficients",
paste0('\ni =~ ', paste(paste0(lin_weight*0+1, '*y', 0:npoints), collapse = ' + ')),
paste0('\ns =~ ', paste(paste0(lin_weight, '*y', 0:npoints), collapse = ' + ')),
paste0('\nq =~ ', paste(paste0(lin_weight^2, '*y', 0:npoints), collapse = ' + ')),
"\ni ~ 0*1
s ~ 5*1
q ~ -1.25*1
i ~~ 4*i
s ~~ .1*s
q ~~ .1*q")

ald_growth_model_to_est <- paste0("
# intercept and slope with fixed coefficients",
paste0('\ni =~ ', paste(paste0(lin_weight*0+1, '*y', 0:npoints), collapse = ' + ')),
paste0('\ns =~ ', paste(paste0(lin_weight, '*y', 0:npoints), collapse = ' + ')),
paste0('\nq =~ ', paste(paste0(lin_weight^2, '*y', 1:npoints), collapse = ' + ')))

ald_growth_data <- lavaan::simulateData(model = ald_growth_model, model.type = 'growth', sample.nobs = 150)

ald_growth_fit <- lavaan::growth(model = ald_growth_model_to_est, data = ald_growth_data)
summary(ald_growth_fit)

ald_growth_data <- mutate(ald_growth_data,
                          recruit_wave = sample(0:(npoints - 3), replace = TRUE, size = n()))

ald_growth_data_l <- gather(mutate(ald_growth_data, ID = 1:n()), key, value, -ID, -recruit_wave) %>%
  extract(key, into = c('var', 'wave'), regex = '(y)(\\d+)') %>%
  mutate(wave = as.numeric(wave)) %>%
  spread(var, value) %>%
  filter(wave >= recruit_wave & wave <= recruit_wave + 3)

ald_growth_data_l_start <- summarize(group_by(ald_growth_data_l, ID),
                                     start = min(wave))
ald_growth_data_l$ID <- factor(ald_growth_data_l$ID,
                               levels = ald_growth_data_l_start$ID[order(ald_growth_data_l_start$start)])

ggplot(ald_growth_data_l, aes(x = wave, y = ID)) +
  geom_point(alpha = .5, position = ajitter) + 
  geom_line(aes(group = ID), alpha = .5, position = ajitter)

ajitter <- position_jitter(width = .05)
acoord <-  coord_cartesian(ylim = c(-7.5, 12.5))
ggplot(ald_growth_data_l, aes(x = wave, y = y)) +
  geom_point(position = ajitter) + 
  geom_smooth(method = 'glm', formula = y ~ poly(x, 2)) + 
  acoord

ggplot(ald_growth_data_l, aes(x = wave, y = y)) +
  geom_point(position = ajitter, alpha = .5) + 
  geom_line(aes(group = ID), position = ajitter,
            alpha = .5) + 
  acoord

ggplot(ald_growth_data_l, aes(x = wave, y = y)) +
  geom_point(position = ajitter, alpha = .5) + 
  geom_line(aes(group = ID), stat = 'smooth', method = 'glm', formula = y ~ poly(x, 1),
            alpha = .5) + 
  acoord

pred_data <- as_tibble(as.data.frame(lavPredict(growth_fit, type = 'ov', method = 'Bartlett')))
pred_data_l <- gather(mutate(pred_data, ID = 1:n()), key, value, -ID) %>%
  extract(key, into = c('var', 'wave'), regex = '(\\w+)(\\d+)') %>%
  mutate(wave = as.numeric(wave), var = 'y_pred') %>%
  spread(var, value) %>%
  left_join(growth_data_l) %>%
  mutate(wave_jitter = wave + runif(n(), -.25, .25))

ggplot(pred_data_l, aes(x = wave_jitter, y = y)) +
  geom_point(alpha = .5) + 
  geom_line(aes(group = ID, y = y_pred), 
            alpha = .1)

ggplot(pred_data_l, aes(x = wave_jitter, y = y)) +
  geom_point(alpha = 1) + 
  geom_line(aes(group = ID, y = y_pred), size = 1,
            alpha = .25) + 
  geom_segment(aes(xend = wave_jitter, yend = y_pred), alpha = 1) + 
  coord_cartesian(ylim = c(5, 9), xlim = c(.5, 1.5))


growth_model_to_est_3wave <- "
					# intercept and slope with fixed coefficients
					i =~ 1*y0 + 1*y1 + 1*y2
					s =~ 0*y0 + 1*y1 + 2*y2
					q =~ 0*y0 + 1*y1 + 4*y2
					# If I don't set this, the model will have -3 df
					y0 ~~ 0*y0
					y1 ~~ 0*y1
					y2 ~~ 0*y2
					"

growth_fit_3wave <- lavaan::growth(model = growth_model_to_est_3wave, data = select(growth_data, -y3))
summary(growth_fit_3wave)

pred_data_3 <- as_tibble(as.data.frame(lavPredict(growth_fit_3wave, type = 'ov', method = 'Bartlett')))
pred_data_3_l <- gather(mutate(pred_data_3, ID = 1:n()), key, value, -ID) %>%
  extract(key, into = c('var', 'wave'), regex = '(\\w+)(\\d+)') %>%
  mutate(wave = as.numeric(wave), var = 'y_pred') %>%
  spread(var, value) %>%
  left_join(growth_data_l) %>%
  mutate(wave_jitter = wave + runif(n(), -.25, .25))

ggplot(pred_data_3_l, aes(x = wave_jitter, y = y)) +
  geom_point(alpha = .5) + 
  geom_line(aes(group = ID, y = y_pred), 
            alpha = .1)

ggplot(pred_data_3_l, aes(x = wave_jitter, y = y)) +
  geom_point(alpha = 1) + 
  geom_line(aes(group = ID, y = y_pred), size = 1,
            alpha = .25) + 
  geom_segment(aes(xend = wave_jitter, yend = y_pred), alpha = 1) + 
  coord_cartesian(ylim = c(5, 9), xlim = c(.5, 1.5))
