library(httr)
library(data.table)
library(tidyverse)
library(jsonlite)
library(progress)
library(lubridate)

# propostas_ano <- function(ano){
#   df <- data.frame()
#   i <- 1
#   while(TRUE){
#     url <- paste0("https://dadosabertos.camara.leg.br/api/v2/proposicoes?siglaTipo=PEC&siglaTipo=PL&siglaTipo=PLP&ano=",ano,"&itens=100&pagina=",i,"&ordem=ASC&ordenarPor=id&dataInicio=1990-01-01&dataFim=2050-12-31")
# 
#     sucesso <- FALSE
#     while(!sucesso){
#       ret <- try(api_prop <- GET(url))
#       sucesso <- !grepl("Error", ret) & status_code(api_prop) == 200
#     }
# 
# 
# 
#     api_prop <- api_prop %>%
#       content("text") %>%
#       fromJSON() %>%
#       .[["dados"]]
# 
#     if(is.null(nrow(api_prop))){
#       break
#     } else {
#       df <- bind_rows(df, api_prop %>%
#                         select(-ementa))
#     }
#     rm(api_prop)
#     i <- i + 1
#   }
# 
#   df
# }
# 
# detalhes_propostas <- function(url){
#   sucesso <- FALSE
#   while(!sucesso){
#     ret <- try(detalhes <- GET(url))
#     sucesso <- !grepl("Error", ret) & status_code(detalhes) == 200
#   }
#   detalhes <- detalhes %>%
#     content("text") %>%
#     fromJSON() %>%
#     .[["dados"]]
# 
#   NOM_PROPOSICAO <- paste0(detalhes$siglaTipo," ", detalhes$numero,"/",detalhes$ano)
#   DES_SITUACAO_PROPOSICAO <- detalhes$statusProposicao$descricaoSituacao
#   DATAPRESENTACAOPROPOSICAO <- detalhes$dataApresentacao %>% substr(., 1, 10) %>% ymd()
#   REGIME <- detalhes$statusProposicao$regime
# 
#   SIG_PARTIDO <- NA
#   SIG_UF <- NA
#   if(!is.null(detalhes$uriAutores)){
#     sucesso <- FALSE
#     while(!sucesso){
#       ret <- try(autores <- GET(detalhes$uriAutores))
#       sucesso <- !grepl("Error", ret) & (status_code(autores) == 200 | status_code(autores) == 404)
#     }
# 
#     if(status_code(autores) != 404){
#       autores <- autores %>%
#         content("text") %>%
#         fromJSON()
# 
#       SIG_PARTIDO <- autores$dados$ultimoStatus$siglaPartido
#       SIG_PARTIDO <- ifelse(is.null(SIG_PARTIDO), NA, SIG_PARTIDO)
#       SIG_UF <- autores$dados$ufNascimento
#       SIG_UF <- ifelse(is.null(SIG_UF), NA, SIG_UF)
#     }
# 
#   }
# 
# 
#   data.frame(NOM_PROPOSICAO = NOM_PROPOSICAO,
#              DES_SITUACAO_PROPOSICAO = ifelse(is.null(DES_SITUACAO_PROPOSICAO), NA,
#                                               DES_SITUACAO_PROPOSICAO),
#              DATAPRESENTACAOPROPOSICAO = DATAPRESENTACAOPROPOSICAO,
#              SIG_PARTIDO = SIG_PARTIDO,
#              SIG_UF = SIG_UF,
#              REGIME = REGIME,
#              stringsAsFactors = FALSE)
# }

###########################################################################
#########################################################################
# ultimo_ano <- as.numeric(substr(Sys.Date(), 1, 4))
# anos <- ultimo_ano #2003:2017 # se já exisitir os outros anos, pode-se definir apenas o último
# dados_propostas <- map_df(anos, propostas_ano)
# 
# fwrite(dados_propostas, 'raw_data/propostas.csv')
# 
# dados_propostas <- fread('raw_data/propostas.csv')
# 
# for(i in anos){
#   urls <- dados_propostas %>%
#     filter(ano == i) %>%
#     pull(uri)
# 
#   barra <- progress_bar$new(total = length(urls),
#                             format = "[:bar] :percent eta: :eta")
#   propostas_detalhes <- NULL
#   while(is.null(propostas_detalhes)){
#     try(
#       propostas_detalhes <- map_df(urls, ~{
#         barra$tick()
#         detalhes_propostas(.x)}
#       )
#     )
#   }
# 
# 
#   write.csv(propostas_detalhes,
#             paste0('raw_data/propostas_detalhes_ano_',i,'.csv'),
#             row.names = FALSE)
#   rm(propostas_detalhes)
# }
# 
# carregar_propostas <- function(ano){
#   read.csv(paste0('raw_data/propostas_detalhes_ano_',ano,'.csv'),
#            stringsAsFactors = FALSE)
# }
# 
# anos <- 2003:ultimo_ano
# propostas_detalhes <- map_df(anos, carregar_propostas)

# propostas_detalhes <- data.frame()
# for(i in 1:length(urls)){
#   print(i)
#   detalhes_tmp <- detalhes_propostas(urls[i])
#   propostas_detalhes <- bind_rows(propostas_detalhes, detalhes_tmp)
#   rm(detalhes_tmp)
# }

#fwrite(propostas_detalhes, 'raw_data/propostas_detalhes.csv')



# Utilizando arquivos csv -------------------------------------------------

filtro_propostas <- fread('raw_data/propostas_detalhes.csv')$NOM_PROPOSICAO

carregar_propostas <- function(ano){
  arquivo_proposta <- paste0("https://dadosabertos.camara.leg.br/arquivos/proposicoes/csv/proposicoes-",
                             ano, ".csv")

  propostas <- read_csv2(arquivo_proposta)

  propostas <- propostas %>%
    filter(siglaTipo %in% c("PEC", "PL", "PLP")) %>%
    mutate(
      NOM_PROPOSICAO = paste0(siglaTipo," ", numero,"/", ano),
      DES_SITUACAO_PROPOSICAO = ultimoStatus_descricaoSituacao,
      DATAPRESENTACAOPROPOSICAO = date(dataApresentacao),
      REGIME = ultimoStatus_regime
    ) %>%
    select(id, NOM_PROPOSICAO, DES_SITUACAO_PROPOSICAO,
           DATAPRESENTACAOPROPOSICAO, REGIME)

  arquivo_autores <- paste0("https://dadosabertos.camara.leg.br/arquivos/proposicoesAutores/csv/proposicoesAutores-",
                            ano, ".csv")

  autores <- read_csv2(arquivo_autores)

  autores <- autores %>%
    rename(SIG_PARTIDO = siglaPartidoAutor,
           SIG_UF = siglaUFAutor) %>%
    select(idProposicao, SIG_PARTIDO, SIG_UF) %>% 
    group_by(idProposicao) %>% 
    mutate(n = 1:n()) %>% 
    filter(n == 1) %>% 
    ungroup() %>% 
    select(-n)  

  propostas <- left_join(propostas, autores,
                         by = c("id" = "idProposicao")) %>%
    select(-id)
}

anos <- 2003:2018

propostas_detalhes <- map_df(anos, carregar_propostas)

write.csv(propostas_detalhes, 'raw_data/propostas_detalhes.csv', row.names = FALSE)