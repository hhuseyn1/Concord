ARG BASE_IMAGE=shared:Development

FROM ${BASE_IMAGE} AS build
WORKDIR /src
COPY . ./Concord.API/
RUN dotnet restore Concord.API
RUN dotnet publish Concord.API -o out

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
RUN sed -i 's|http://archive.ubuntu.com|https://archive.ubuntu.com|g; s|http://security.ubuntu.com|https://security.ubuntu.com|g' /etc/apt/sources.list.d/*.sources /etc/apt/sources.list 2>/dev/null; \
    apt-get update \
    && apt-get install -y --no-install-recommends libgssapi-krb5-2 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /App
COPY --from=build /src/out .
ENTRYPOINT ["dotnet", "Concord.API.dll"]