ARG IMAGE=store/intersystems/iris-community:2021.1.0.215.0
FROM ${IMAGE}

USER ${ISC_PACKAGE_MGRUSER}

ENV SRC_DIR=/tmp
COPY --chown=irisowner ./dc/ $SRC_DIR/dc

ARG ISC_CPF_MERGE_FILE=$ISC_PACKAGE_INSTALLDIR/merge.cpf

USER root

COPY --chown=${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} merge.cpf $ISC_PACKAGE_INSTALLDIR
COPY --chown=${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} irissession.sh /
RUN chmod +x /irissession.sh 

SHELL ["/irissession.sh"]

USER ${ISC_PACKAGE_MGRUSER}

RUN \  
  set $namespace = "USER"  \
  do $System.OBJ.LoadDir("/tmp/dc","ck",,1)


SHELL ["/bin/bash", "-c"]

WORKDIR /home/irisowner

HEALTHCHECK --interval=5s CMD /irisHealth.sh || exit 1