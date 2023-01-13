ARG GOMODIFYTAGS_VERSION=v1.16.0
ARG GOPLAY_VERSION=v1.0.0
ARG GOTESTS_VERSION=v1.6.0
ARG DLV_VERSION=v1.20.1
ARG MOCKERY_VERSION=v2.16.0
ARG GOMOCK_VERSION=v1.6.0
ARG MOCKGEN_VERSION=v1.6.0
ARG GOPLS_VERSION=v0.11.0
ARG GOLANGCILINT_VERSION=v1.50.1
ARG IMPL_VERSION=v1.1.0
ARG GOPKGS_VERSION=v2.1.2

FROM qmcgaw/binpot:gomodifytags-${GOMODIFYTAGS_VERSION} AS gomodifytags
FROM qmcgaw/binpot:goplay-${GOPLAY_VERSION} AS goplay
FROM qmcgaw/binpot:gotests-${GOTESTS_VERSION} AS gotests
FROM qmcgaw/binpot:dlv-${DLV_VERSION} AS dlv
FROM qmcgaw/binpot:mockery-${MOCKERY_VERSION} AS mockery
FROM qmcgaw/binpot:gomock-${GOMOCK_VERSION} AS gomock
FROM qmcgaw/binpot:mockgen-${MOCKGEN_VERSION} AS mockgen
FROM qmcgaw/binpot:gopls-${GOPLS_VERSION} AS gopls
FROM qmcgaw/binpot:golangci-lint-${GOLANGCILINT_VERSION} AS golangci-lint
FROM qmcgaw/binpot:impl-${IMPL_VERSION} AS impl
FROM qmcgaw/binpot:gopkgs-${GOPKGS_VERSION} AS gopkgs

FROM ubuntu:latest

ENV GOLANG_VERSION 1.19.5
ENV PATH /usr/local/go/bin:$PATH

RUN apt update; \
		apt install -y --no-install-recommends ca-certificates wget

RUN echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ stable main" | tee /etc/apt/sources.list.d/azlux.list; \
		wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg

RUN set -eux; \
	apt update; \
	apt install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config \
		git \
		zsh \
		fzf \
		exa \
		broot \
		btop \
		bat \
		openssh-client \
	; \
	rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  url="https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz"; \
	wget -O go.tgz "$url" --progress=dot:giga; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin"; \
		chmod -R 777 "$GOPATH"; \
		go env -w GOFLAGS=-buildvcs=false

ARG USERNAME=luca
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
		&& apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

WORKDIR /home/$USERNAME

USER $USERNAME

RUN mkdir -p /home/$USERNAME/.vscode-server/extensions \
        /home/$USERNAME/.vscode-server-insiders/extensions \
    && chown -R $USERNAME \
        /home/$USERNAME/.vscode-server \
        /home/$USERNAME/.vscode-server-insiders

RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended; \
		chsh --shell /bin/zsh luca; \
		git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k; \
		git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions; \
		git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab; \
		git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions; \
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

COPY --chown=$USERNAME .zshrc .p10k.zsh /home/$USERNAME

RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
# RUN nvm install node
# RUN corepack enable

ENV TZ Asia/Shanghai

USER root

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
		echo 'Asia/Shanghai' > /etc/timezone

ENV MIRRORS "http://mirrors.tuna.tsinghua.edu.cn"
    # MIRRORS="http://mirrors.aliyun.com"

RUN sed -i "s@http://.*archive.ubuntu.com@$MIRRORS@g" /etc/apt/sources.list; \
    sed -i "s@http://.*security.ubuntu.com@$MIRRORS@g" /etc/apt/sources.list

USER $USERNAME

COPY --chown=$USERNAME --from=gomodifytags /bin /go/bin/gomodifytags
COPY --chown=$USERNAME --from=goplay  /bin /go/bin/goplay
COPY --chown=$USERNAME --from=gotests /bin /go/bin/gotests
COPY --chown=$USERNAME --from=dlv /bin /go/bin/dlv
COPY --chown=$USERNAME --from=mockery /bin /go/bin/mockery
COPY --chown=$USERNAME --from=gomock /bin /go/bin/gomock
COPY --chown=$USERNAME --from=mockgen /bin /go/bin/mockgen
COPY --chown=$USERNAME --from=gopls /bin /go/bin/gopls
COPY --chown=$USERNAME --from=golangci-lint /bin /go/bin/golangci-lint
COPY --chown=$USERNAME --from=impl /bin /go/bin/impl
COPY --chown=$USERNAME --from=gopkgs /bin /go/bin/gopkgs
