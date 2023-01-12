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
		go install github.com/cweill/gotests/gotests@v1.6.0; \
    go install github.com/fatih/gomodifytags@v1.16.0; \
    go install github.com/josharian/impl@v1.1.0; \
    go install github.com/haya14busa/goplay/cmd/goplay@v1.0.0; \
    go install github.com/go-delve/delve/cmd/dlv@latest; \
    go install honnef.co/go/tools/cmd/staticcheck@latest; \
    go install golang.org/x/tools/gopls@latest; \
    go install github.com/ramya-rao-a/go-outline@v0.0.0-20210608161538-9736a4bde949; \
		go clean -cache; \
		go env -w GOFLAGS=-buildvcs=false

RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended; \
		chsh --shell /bin/zsh root; \
		git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k; \
		git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions; \
		git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab; \
		git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions; \
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

COPY .zshrc .p10k.zsh /root

RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
# RUN nvm install node
# RUN corepack enable

ENV TZ Asia/Shanghai
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
		echo 'Asia/Shanghai' > /etc/timezone

ENV MIRRORS "http://mirrors.tuna.tsinghua.edu.cn"
    # MIRRORS="http://mirrors.aliyun.com"

RUN sed -i "s@http://.*archive.ubuntu.com@$MIRRORS@g" /etc/apt/sources.list; \
    sed -i "s@http://.*security.ubuntu.com@$MIRRORS@g" /etc/apt/sources.list
