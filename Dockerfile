ARG IMAGE=containers.intersystems.com/intersystems/iris:2022.1.0.131.0
FROM ${IMAGE}

USER ${ISC_PACKAGE_MGRUSER}

ENV SRC_DIR=/tmp
COPY --chown=irisowner ./dc/ $SRC_DIR/dc

ARG ISC_CPF_MERGE_FILE=$ISC_PACKAGE_INSTALLDIR/merge.cpf

USER root

COPY --chown=${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} merge.cpf $ISC_PACKAGE_INSTALLDIR
COPY --chown=${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} irissession.sh /
RUN chmod +x /irissession.sh 

RUN touch /iris-main.log
RUN chmod +777 /iris-main.log
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /iris-main.log

SHELL ["/irissession.sh"]

USER ${ISC_PACKAGE_MGRUSER}

RUN \  
  set $namespace = "USER"  \
  do $System.OBJ.LoadDir("/tmp/dc","ck",,1)


SHELL ["/bin/bash", "-c"]


WORKDIR /home/irisowner
RUN rm -f iris-main.log

ENTRYPOINT pwd && whoami && ls -al && /tini -- /iris-main

HEALTHCHECK --interval=5s CMD /irisHealth.sh || exit 1