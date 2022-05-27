import pytest


@pytest.fixture(scope="session")
def owner(accounts):
    return accounts[0]

@pytest.fixture(scope="session")
def receiver(accounts):
    return accounts[1]

@pytest.fixture(scope="session")
def token(owner, project):
    return owner.deploy(project.Token)


@pytest.fixture
def sudo(accounts):
    return accounts[-1]


@pytest.fixture
def token(project, sudo):
    return sudo.deploy(project.TestToken)


@pytest.fixture
def new_strategy(project, token, sudo):
    def create_strategy():
        return sudo.deploy(project.TestStrategy, token)

    return create_strategy


@pytest.fixture
def mint_tokens(token, sudo):
    def mint_tokens(account):
        token.mint(account, "100 ether", sender=sudo)

    return mint_tokens


@pytest.fixture
def portfolio(project, token, sudo):
    return sudo.deploy(project.Portfolio, token)

