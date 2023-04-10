FROM mcr.microsoft.com/mssql/server:2019-latest

# Set environment variables for SQL Server instance
ENV SA_PASSWORD=cGFzc3dvcmQ=
ENV ACCEPT_EULA=Y

# Create a database directory
RUN mkdir -p /var/opt/mssql/data

# Grant permissions to the database directory
RUN chmod -R g=u /var/opt/mssql/data

# Create a new user with admin privileges
ENV MSSQL_PID=Developer
ENV MSSQL_AGENT_ENABLED=true
ENV MSSQL_COLLATION=SQL_Latin1_General_CP1_CI_AS
ENV MSSQL_TCP_PORT=1433
ENV MSSQL_LCID=1033
ENV MSSQL_MEMORY_LIMIT_MB=2048
ENV MSSQL_USERNAME=worker
ENV MSSQL_PASSWORD=cGFzc3dvcmQ=
ENV MSSQL_USER_HOME=/home/worker

USER root
RUN useradd -u 10101 -m -s /bin/bash -p $(openssl passwd -1 ${MSSQL_PASSWORD}) ${MSSQL_USERNAME}
RUN usermod -aG sudo ${MSSQL_USERNAME}

# Enable remote connections
RUN echo 'export MSSQL_PID=Developer' >> ~/.bashrc
RUN echo 'export MSSQL_TCP_PORT=1433' >> ~/.bashrc
RUN echo 'export MSSQL_COLLATION=SQL_Latin1_General_CP1_CI_AS' >> ~/.bashrc
RUN echo 'export MSSQL_LCID=1033' >> ~/.bashrc
RUN echo 'export MSSQL_USER_HOME=/home/newuser' >> ~/.bashrc
RUN echo 'export ACCEPT_EULA=Y' >> ~/.bashrc
RUN echo 'export SA_PASSWORD=cGFzc3dvcmQ=' >> ~/.bashrc

# Add a volume to persist data
VOLUME /var/opt/mssql/data

# Expose the SQL Server port
EXPOSE 1433

# Start SQL Server
CMD /opt/mssql/bin/sqlservr

# for password convert         echo -n "password" | base64
# docker build -t sqlserver .
# docker run -d -p 1433:1433 -v my_sql_data:/var/opt/mssql/data sqlserver
