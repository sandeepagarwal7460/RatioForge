FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app
COPY . .
RUN dotnet restore Source/RatioForge.sln
RUN dotnet publish Source/RatioForge/RatioForge.csproj -c Release -o /out

FROM mcr.microsoft.com/dotnet/aspnet:8.0

# Install Xvfb and X11 libraries so Windows Forms can run headlessly
RUN apt-get update && apt-get install -y \
    libfontconfig1 \
    libgdiplus \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /out .

ENV PORT=10000
EXPOSE 10000

# Wrap execution with xvfb-run to simulate a display screen
CMD ["xvfb-run", "--server-args='-screen 0 1024x768x24'", "dotnet", "RatioForge.dll"]
