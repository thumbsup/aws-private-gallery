FROM public.ecr.aws/lambda/nodejs:20

# Install extra utilities
RUN dnf update -y && dnf install zip -y

# working folder
RUN mkdir /build
WORKDIR /build

# install dependencies (highly cacheable)
COPY package*.json /build/
RUN npm install

# add source code
COPY index.js /build/index.js
COPY lib/ /build/lib/

# Run tests & prune dev dependencies
RUN npm test && npm prune --production

# zip entire context and stream output
RUN zip -r /build/dist.zip . > /dev/null
CMD ["cat", "/build/dist.zip"]
