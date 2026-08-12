# Use the official .NET 8 SDK image to build the app
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy everything from your repo into the container
COPY . .

# Restore and publish the application in Release mode
# Note: Pointing to the solution file found in your repository structure
RUN dotnet restore Source/RatioForge.sln
RUN dotnet publish Source/RatioForge/RatioForge.csproj -c Release -o /out

# Use a lightweight Linux runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /out .

# Render requires web services to listen on a port. 
# Even if RatioForge doesn't serve web traffic, a dummy web listener 
# or proper process mapping may be required if Render marks it dead for lack of open ports.
ENV PORT=10000
EXPOSE 10000

# Run the application
ENTRYPOINT ["dotnet", "RatioForge.dll"]
