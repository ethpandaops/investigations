// ethPandaOps team authors configuration
export const authors = {
    'samcm': {
        name: 'Sam Calder-Mason',
        username: 'samcm',
        avatar: 'https://github.com/samcm.png',
        github: 'https://github.com/samcm',
        twitter: 'https://twitter.com/samcm_'
    },
    'parithosh': {
        name: 'Parithosh Jayanthi',
        username: 'parithosh',
        avatar: 'https://github.com/parithosh.png',
        github: 'https://github.com/parithosh',
        twitter: 'https://twitter.com/paraborium'
    },
    'pk910': {
        name: 'pk910',
        username: 'pk910',
        avatar: 'https://github.com/pk910.png',
        github: 'https://github.com/pk910'
    },
    'savid': {
        name: 'Andrew Davis',
        username: 'Savid',
        avatar: 'https://github.com/Savid.png',
        github: 'https://github.com/Savid'
    },
    'skylenet': {
        name: 'Rafael Matias',
        username: 'skylenet',
        avatar: 'https://github.com/skylenet.png',
        github: 'https://github.com/skylenet'
    },
    'mattevans': {
        name: 'Matty Evans',
        username: 'mattevans',
        avatar: 'https://github.com/mattevans.png',
        github: 'https://github.com/mattevans'
    },
    'qu0b': {
        name: 'Stefan',
        username: 'qu0b',
        avatar: 'https://github.com/qu0b.png',
        github: 'https://github.com/qu0b'
    },
    'barnabasbusa': {
        name: 'Barnabas Busa',
        username: 'barnabasbusa',
        avatar: 'https://github.com/barnabasbusa.png',
        github: 'https://github.com/barnabasbusa'
    },
    // Generic ethPandaOps author for team posts
    'ethpandaops': {
        name: 'ethPandaOps',
        username: 'ethpandaops',
        avatar: 'https://github.com/ethpandaops.png',
        github: 'https://github.com/ethpandaops',
        twitter: 'https://twitter.com/ethpandaops'
    }
};

export function getAuthor(id) {
    const key = id?.toLowerCase();
    return authors[key] || {
        name: id,
        username: id,
        avatar: `https://github.com/${id}.png`,
        github: `https://github.com/${id}`
    };
}
