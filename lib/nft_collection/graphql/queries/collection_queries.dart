const collectionQuery = r'''
    query GetCollections($creators: [String!]! = [], $offset: Int64! = 0, $size: Int64! = 100) {
  collections(
    creators: $creators,
    offset: $offset,
    size: $size,
  ) {
    id
    externalID
    blockchain
    contracts
    description
    imageURL
    thumbnailURL
    items
    name
    creator
    published
    source
    sourceURL
    projectURL
    createdAt
    lastUpdatedTime
    lastActivityTime
  }
}
''';
